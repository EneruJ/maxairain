import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:maxairain/main.dart';

class Materiaux {
  String id;
  String nom;
  int quantite;

  Materiaux({required this.id, required this.nom, required this.quantite});

  factory Materiaux.fromJson(Map<String, dynamic> json) {
    return Materiaux(
      id: json['_id'],
      nom: json['nom'],
      quantite: json['quantite'],
    );
  }
}

class Reservation {
  final String idUser;
  final List<Materiaux> materiauxList;
  final String? id_materiel;
  String? objectId;
  final bool isReserved;

  Reservation({
    required this.idUser,
    required this.materiauxList,
    this.id_materiel,
    this.objectId,
    required this.isReserved,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final List<dynamic> materiauxJsonList = json['materiauxList'];
    final List<Materiaux> materiauxList = materiauxJsonList
        .map<Materiaux>((materielJson) => Materiaux.fromJson(materielJson))
        .toList();

    return Reservation(
      idUser: json['idUser'],
      materiauxList: materiauxList,
      id_materiel: json['id_materiel'],
      objectId: json['_id'] as String?,
      isReserved: json['id_materiel'] != null,
    );
  }
}

class Logged extends StatefulWidget {
  const Logged({Key? key}) : super(key: key);

  @override
  _LoggedState createState() => _LoggedState();
}

class _LoggedState extends State<Logged> {
  List<Materiaux> allMateriaux = [];
  List<Materiaux> selectedMateriaux = [];

  Reservation? firstReservation;

  @override
  void initState() {
    super.initState();
    fetchReservationData();
    fetchMateriaux();
  }

  Future<void> fetchReservationData() async {
    final url = Uri.parse('https://testmaxairain-bf60.restdb.io/rest/reservation');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-apikey': '93c82103771ae560c043bb618cb6da4b9eca0',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> reservationsData = json.decode(response.body);
      if (reservationsData.isNotEmpty) {
        final firstReservationData = reservationsData[0] as Map<String, dynamic>;
        final objectId = firstReservationData['_id'] as String;
        final userData = firstReservationData['id_user'] as List<dynamic>;
        final userDataMap = userData[0] as Map<String, dynamic>;
        final idUser = '${userDataMap['name']} ${userDataMap['lastname']} (${userDataMap['poste']})';
        final List<dynamic>? materiauxData = firstReservationData['id_materiel'] as List<dynamic>?;

        List<Materiaux> materiauxList;

        if (materiauxData != null && materiauxData.isNotEmpty) {
          materiauxList = materiauxData.map<Materiaux>((item) {
            final id = item['_id'] as String;
            final nom = item['nom'] as String;
            final quantite = item['quantite'] as int;
            return Materiaux(id: id, nom: nom, quantite: quantite);
          }).toList();
        } else {
          materiauxList = await fetchFullMateriauxList();
        }

        setState(() {
          firstReservation = Reservation(objectId: objectId ,idUser: idUser, materiauxList: materiauxList, isReserved: materiauxData != null);
        });
        print(firstReservation);
      }
    } else {
      print('Echec de la récupération des réservations');
    }
  }

  Future<List<Materiaux>> fetchFullMateriauxList() async {
    final url = Uri.parse('https://testmaxairain-bf60.restdb.io/rest/materiaux');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-apikey': '93c82103771ae560c043bb618cb6da4b9eca0',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> materiauxData = data as List<dynamic>;
      return materiauxData.map<Materiaux>((item) {
        final id = item['_id'] as String;
        final nom = item['nom'] as String;
        final quantite = item['quantite'] as int;
        return Materiaux(id: id, nom: nom, quantite: quantite);
      }).toList();
    } else {
      print('Failed to fetch materiaux data');
      return [];
    }
  }

  Future<void> fetchMateriaux() async {
    final url = Uri.parse('https://testmaxairain-bf60.restdb.io/rest/materiaux');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-apikey': '93c82103771ae560c043bb618cb6da4b9eca0',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> materiauxData = data as List<dynamic>;
      allMateriaux = materiauxData.map<Materiaux>((item) {
        final id = item['_id'] as String;
        final nom = item['nom'] as String;
        final quantite = item['quantite'] as int;
        return Materiaux(id: id, nom: nom, quantite: quantite);
      }).toList();
      setState(() {});
    } else {
      print('Echec de la récupération des matériaux');
    }
  }

  Future<void> updateMateriauxQuantity(Materiaux materiaux, bool op) async {
    final url = Uri.parse('https://testmaxairain-bf60.restdb.io/rest/materiaux/${materiaux.id}');
    final int newquantite;
    if (op) {
      newquantite = materiaux.quantite + 1;
    } else {
      newquantite = materiaux.quantite - 1;
    }
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-apikey': '93c82103771ae560c043bb618cb6da4b9eca0',
      },
      body: json.encode({
        'quantite': newquantite,
      }),
    );
    if (response.statusCode == 200) {
      print('Updated materiaux quantity: ${materiaux.nom}');
    } else {
      print('Failed to update materiaux quantity: ${materiaux.nom}');
    }
  }

  Future<void> updateReservation() async {
    if (firstReservation != null) {
      final url = Uri.parse('https://testmaxairain-bf60.restdb.io/rest/reservation/${firstReservation!.objectId}');
      final List<Map<String, dynamic>> materiauxData = selectedMateriaux.map((materiaux) => {
        '_id': materiaux.id,
        'nom': materiaux.nom,
        'quantite': materiaux.quantite,
      }).toList();
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-apikey': '93c82103771ae560c043bb618cb6da4b9eca0',
        },
        body: json.encode({
          'id_materiel': materiauxData,
        }),
      );

      if (response.statusCode == 200) {
        print('Updated reservation: ${firstReservation!.objectId}');
      } else {
        print('Failed to update reservation: ${firstReservation!.objectId}');
      }
    }
  }

  Future<void> deleteReservation() async {
    if (firstReservation != null) {
      final url = Uri.parse('https://testmaxairain-bf60.restdb.io/rest/reservation/${firstReservation!.objectId}');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-apikey': '93c82103771ae560c043bb618cb6da4b9eca0',
        },
      );
      if (response.statusCode == 200) {
        print('Deleted reservation: ${firstReservation!.objectId}');
      } else {
        print('Failed to delete reservation: ${firstReservation!.objectId}');
      }
    }
  }

  Future<void> handleValidation() async {
    final selectedMateriauxSet = selectedMateriaux.toSet();
    final firstReservationMateriauxSet = firstReservation!.materiauxList.toSet();

    if (selectedMateriauxSet.containsAll(firstReservationMateriauxSet) &&
        firstReservationMateriauxSet.containsAll(selectedMateriauxSet)) {
      for (Materiaux materiaux in selectedMateriaux) {
        await updateMateriauxQuantity(materiaux, true);
      }
      await deleteReservation();
    } else {
      for (Materiaux materiaux in selectedMateriaux) {
        await updateMateriauxQuantity(materiaux, false);
      }
      await updateReservation();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Validation successful'),
          content: const Text('Saisie du matériel terminée. Retour à l\'écran d\'accueil'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (firstReservation == null || firstReservation!.materiauxList.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Ecran de saisie du matériel',
            style: TextStyle(color: Color(0xFF379EC1)),
          ),
          backgroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Chargement...',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    } else {
      if (selectedMateriaux.isEmpty) {
        selectedMateriaux.addAll(firstReservation!.materiauxList);
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Ecran de saisie du matériel',
            style: TextStyle(color: Color(0xFF379EC1)),
          ),
          backgroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Utilisateur: ${firstReservation!.idUser}',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Matériel à emprunter / récupérer :',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: firstReservation!.materiauxList.length,
                    itemBuilder: (context, index) {
                      final materiaux = firstReservation!.materiauxList[index];

                      if (materiaux.quantite == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
                          child: Row(
                            children: [
                              Text(
                                materiaux.nom,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Text(
                                ' - Non disponible',
                                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        );
                      }

                      return CheckboxListTile(
                        title: Text(materiaux.nom),
                        value: selectedMateriaux.contains(materiaux),
                        onChanged: (value) {
                          setState(() {
                            if (value != null && value) {
                              selectedMateriaux.add(materiaux);
                            } else {
                              selectedMateriaux.remove(materiaux);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: handleValidation,
                  child: const Text('Valider la sélection'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}