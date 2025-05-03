import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <-- Importe Riverpod
import 'firebase_options.dart';
import 'screens/auth_checker.dart'; // <-- On va créer ce fichier bientôt

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // On enveloppe l'application avec ProviderScope pour que Riverpod fonctionne
  runApp(
    const ProviderScope( // <-- Ajoute ProviderScope ici
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImmunoWarriors',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // On remplace Placeholder par AuthChecker qui gérera la navigation
      home: const AuthChecker(), // <-- Utilise notre futur AuthChecker
    );
  }
}