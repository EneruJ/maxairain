import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:maxairain/logged.dart';
import 'dart:io';

class Identification extends StatefulWidget {
  const Identification({Key? key}) : super(key: key);

  @override
  _IdentificationState createState() => _IdentificationState();
}

class _IdentificationState extends State<Identification> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras.last, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String> _convertImageToBase64(String? imagePath) async {
    if (imagePath == null) {
      throw Exception('Image path is null');
    }

    final File imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    final formattedImage = 'data:image/jpeg;base64,$base64Image';
    return formattedImage;
  }

  Future<void> _sendImageToApi(String base64Image) async {
    try {
      const apiUrl = 'https://facerecognitionmaxairain.osc-fr1.scalingo.io/api/v1/face-recognition';
      final headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      };

      final body = jsonEncode({
        'picture': base64Image,
      });

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final isSimilar = responseData['similar'] ?? false;
        final score = responseData['score'];
        final userId = responseData['userId'] ?? '';

        if (isSimilar) {
          print('Identification validée, utilisateur trouvé. Score code: $score, userId: $userId');

          // Show success notification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Identification validée, veuillez patienter.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ).closed.then((_) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Logged(userId: userId)),
            );
          });
        } else {
          print('Identification non validée, utilisateur non trouvé. Score code: $score');

          // Show failure notification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.error,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Identification non validée. Utilisateur non trouvé.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        print('Echec de l\'envoi de l\'image. Status code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  'Echec de l\'envoi de l\'image.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      print('Echec de l\'envoi de l\'image. Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Identification',
          style: TextStyle(color: Color(0xFF379EC1)),
        ),
        backgroundColor: Colors.white,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_controller.value.isInitialized) {
              return CameraPreview(_controller);
            } else {
              return const Center(child: Text('Camera initialization failed'));
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF379EC1),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: const Text(
            'Placez votre visage au centre de l\'écran',
            style: TextStyle(
              fontSize: 20.0,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF379EC1),
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();

            final base64Image = await _convertImageToBase64(image.path);

            await _sendImageToApi(base64Image);

          } catch (e) {
            print('Error capturing image: $e');
          }
        },
        label: const Text('S\'identifier'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
