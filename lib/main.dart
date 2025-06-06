import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'screens/auth_checker.dart'; // Your existing authentication checker
import 'screens/splash_screen.dart'; // <<< NEW: Import your splash screen

// Assure-toi d'importer les modèles qui auront des Adapters Hive (pour les types)
import 'models/ressources_defensives.dart';
import 'models/laboratoire_recherche.dart';
import 'models/memoire_immunitaire.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters for your models
  Hive.registerAdapter(RessourcesDefensivesAdapter());
  Hive.registerAdapter(LaboratoireRechercheAdapter());
  Hive.registerAdapter(MemoireImmunitaireAdapter());
  // TODO: Register Adapters for other models if you store them in Hive

  // Open necessary Hive boxes
  await Hive.openBox<RessourcesDefensives>('resourcesBox');
  await Hive.openBox<LaboratoireRecherche>('researchBox');
  await Hive.openBox<MemoireImmunitaire>('immuneMemoryBox');
  // TODO: Open other boxes if necessary

  runApp(
    const ProviderScope(
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // The app now starts with the SplashScreen
      home: const SplashScreen(),
    );
  }
}