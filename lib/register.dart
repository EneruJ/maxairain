import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:maxairain/main.dart';

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  String? _imagePath;
  String? _selectedJob;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();

  final List<String> jobOptions = [
    'Agent de sécurité',
    'Agent de surveillance',
    'Agent de gardiennage',
    'Agent de protection',
  ];

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
    _nameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<String> _convertImageToBase64(String? imagePath) async {
    if (imagePath == null) {
      throw Exception('Image path is null');
    }

    final File imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    return base64Image;
  }

  Future<void> _sendImageToApi(
      String base64Image, String name, String lastName) async {
    try {
      const apiUrl = 'https://testmaxairain-bf60.restdb.io/rest/registertest';
      final headers = {
        'Content-Type': 'application/json',
        'x-apikey': '93c82103771ae560c043bb618cb6da4b9eca0',
      };

      final body = jsonEncode({
        'image': base64Image,
        'name': name,
        'lastname': lastName,
        'poste': _selectedJob,
        'date': DateTime.now().toIso8601String(),
      });

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Registration sent to API');
        // Add a snackbar to inform the user that the registration was sent
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
                  'Inscription validée',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.green, // Set your desired background color
            duration: const Duration(seconds: 2), // Set the display duration
            behavior: SnackBarBehavior.floating, // Set the behavior (e.g., floating, fixed)
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Set border radius
            ),
          ),
          // Add redirection to the identification page
        ).closed.then((_) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        });
      } else {
        throw Exception('Failed to send registration to API');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final imagePath = await _controller.takePicture();
      setState(() {
        _imagePath = imagePath.path;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _pickImage() async {
    try {
      final imagePicker = ImagePicker();
      final image = await imagePicker.pickImage(source: ImageSource.gallery);
      setState(() {
        _imagePath = image!.path;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _register() async {
    try {
      if (_formKey.currentState!.validate()) {
        final name = _nameController.text;
        final lastName = _lastNameController.text;

        if (_imagePath != null) {
          final base64Image = await _convertImageToBase64(_imagePath);
          await _sendImageToApi(base64Image, name, lastName);
        } else {
          throw Exception('Aucune image sélectionnée');
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  height: 300,
                  width: 300,
                  child: _imagePath == null
                      ? const Center(
                    child: Text('Aucune image'),
                  )
                      : Image.file(
                    File(_imagePath!),
                    height: 300,
                    width: 300,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _takePicture,
                  icon: const Icon(Icons.camera_alt),
                ),
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Prénom obligatoire';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nom obligatoire';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Poste',
                ),
                value: _selectedJob,
                items: jobOptions.map((String job) {
                  return DropdownMenuItem<String>(
                    value: job,
                    child: Text(job),
                  );
                }).toList(),
                onChanged: (String? selectedJob) {
                  setState(() {
                    _selectedJob = selectedJob;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Sélectionnez un poste';
                  }
                  return null;
                },
              ),
            ),
            ElevatedButton(
              onPressed: _register,
              child: const Text('S\'inscrire'),
            ),
          ],
        ),
      ),
    );
  }
}
