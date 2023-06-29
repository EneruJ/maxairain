import 'package:flutter/material.dart';
import 'package:maxairain/identification.dart';
import 'package:maxairain/register.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaxAirain',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: const Directionality(
        textDirection: TextDirection.ltr, // Set the appropriate text direction here
        child: HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              // Add image from lib/assets
              'assets/images/MaxAirain2.png',
              width: 300,
              height: 300,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Register()),
                );
              },
              child: const Text('Inscription'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Identification()),
                );
              },
              child: const Text('Identification'),
            ),
          ],
        ),
      ),
    );
  }
}
