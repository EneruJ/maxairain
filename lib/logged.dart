import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoggedPage extends StatefulWidget {
  final String userId;

  LoggedPage({required this.userId});

  @override
  _LoggedPageState createState() => _LoggedPageState();
}

class _LoggedPageState extends State<LoggedPage> {
  String firstName = '';
  String lastName = '';
  String role = '';
  List<String> materialsList = [];
  List<Map<String, dynamic>> materialsUser = [];
  List<Map<String, dynamic>> allMaterials = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {

    final userResponse = await http.get(Uri.parse(
        'https://localhost:8080/api/v1/users/get?userId=${widget.userId}'));


    if (userResponse.statusCode == 200) {
      final userData = jsonDecode(userResponse.body);
      setState(() {
        firstName = userData['firstname'];
        lastName = userData['lastname'];
        role = userData['role'];
      });
    }

    final reservationResponse = await http.get(Uri.parse(
        'https://localhost:8080/api/v1/reservations/get?userId=${widget.userId}'));

    if (reservationResponse.statusCode == 200) {
      final reservationData = jsonDecode(reservationResponse.body);
      final materials = reservationData['materials'];

      if (materials.isNotEmpty) {
        for (String materialId in materials) {
          final materialResponse = await http.get(Uri.parse(
              'https://localhost:8080/api/v1/materials/get?materialId=$materialId'));

          if (materialResponse.statusCode == 200) {
            final materialData = jsonDecode(materialResponse.body);
            setState(() {
              materialsUser.add({
                'materialId': materialData['materialId'],
                'name': materialData['name'],
                'quantityA': materialData['quantityA'],
                'quantityT': materialData['quantityT'],
              });
            });
          }
        }
      }
    }

    final allMaterialsResponse = await http.get(Uri.parse(
        'https://localhost:8080/api/v1/materials/getAll'));

    if (allMaterialsResponse.statusCode == 200) {
      final materialsData = jsonDecode(allMaterialsResponse.body);
      setState(() {
        allMaterials = materialsData;
        materialsList = List.generate(
            allMaterials.length, (index) => allMaterials[index]['materialId']);
      });
    }
  }

  void handleValidation() async {
    if (materialsList.isEmpty && materialsUser.isEmpty) {
      // Step 10: Increase quantityA by 1 for each material in materialsUser
      for (var material in materialsUser) {
        final response = await http.post(Uri.parse(
            'https://localhost:8080/api/v1/materials/update'),
            body: {
              'materialId': material['materialId'],
              'quantityA': (material['quantityA'] + 1).toString(),
            });

        if (response.statusCode == 200) {
          print('Quantity updated successfully');
        }
      }
    } else {
      List<String> checkedMaterials = [];
      for (var material in allMaterials) {
        if (materialsList.contains(material['materialId'])) {
          checkedMaterials.add(material['materialId']);
        }
      }
      setState(() {
        materialsList = checkedMaterials;
      });

      for (var material in materialsUser) {
        final response = await http.post(Uri.parse(
            'https://localhost:8080/api/v1/materials/update'),
            body: {
              'materialId': material['materialId'],
              'quantityA': (material['quantityA'] - 1).toString(),
            });

        if (response.statusCode == 200) {
          print('Quantity updated successfully');
        }
      }
    }

    // TODO: Add notification and navigation logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ecran de saisie du matériel',
          style: TextStyle(color: Color(0xFF379EC1)),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Text('First Name: $firstName'),
          Text('Last Name: $lastName'),
          Text('Role: $role'),
          Text('Selectionnez les matériaux à emprunter / rendre :'),
          Expanded(
            child: ListView.builder(
              itemCount: allMaterials.length,
              itemBuilder: (context, index) {
                final material = allMaterials[index];
                return CheckboxListTile(
                  title: Text(material['name']),
                  value: materialsList.contains(material['materialId']),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        materialsList.add(material['materialId']);
                      } else {
                        materialsList.remove(material['materialId']);
                      }
                    });
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: handleValidation,
            child: const Text('Validation'),
          ),
        ],
      ),
    );
  }
}
