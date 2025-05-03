import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImmunoWarriors', // Le titre de ton application
      theme: ThemeData(
        primarySwatch: Colors.blue, // Une couleur de thème de base
      ),
      home: const Placeholder(), // On met un Placeholder pour l'instant
    );
  }
}