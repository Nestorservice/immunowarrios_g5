import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'screens/auth_checker.dart';
// Assure-toi d'importer les modèles qui auront des Adapters Hive (pour les types)
import 'models/ressources_defensives.dart';
import 'models/laboratoire_recherche.dart';
import 'models/memoire_immunitaire.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // **AJOUT IMPORTANT :** Initialisation de Hive
  await Hive.initFlutter();

  // **AJOUT IMPORTANT :** Enregistrer les Adapters pour tes modèles
  // Ces Adapters sont définis dans les fichiers .g.dart que tu as importés
  Hive.registerAdapter(RessourcesDefensivesAdapter()); // Le nom de la classe Adapter générée
  Hive.registerAdapter(LaboratoireRechercheAdapter()); // Le nom de la classe Adapter générée
  Hive.registerAdapter(MemoireImmunitaireAdapter()); // Le nom de la classe Adapter générée
  // TODO: Enregistrer les Adapters pour d'autres modèles si tu les stockes dans Hive

  // **AJOUT IMPORTANT :** Ouvrir les boîtes Hive nécessaires
  // Assure-toi d'utiliser les mêmes noms de boîtes que dans hive_service.dart
  await Hive.openBox<RessourcesDefensives>('resourcesBox');
  await Hive.openBox<LaboratoireRecherche>('researchBox');
  await Hive.openBox<MemoireImmunitaire>('immuneMemoryBox');
  // TODO: Ouvrir d'autres boîtes si nécessaire

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// ... (Le reste de ta classe MyApp) ...
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
      home: const AuthChecker(),
    );
  }
}