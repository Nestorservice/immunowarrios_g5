import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // Assure-toi que le package UUID est ajouté et importé
import '../models/bacterie.dart';
import '../models/base_virale.dart';
import '../models/virus.dart';
import '../state/auth_state_provider.dart'; // Importe TOUS nos providers
// Importe les pages pour la navigation future
import 'scanner_page.dart';
import 'bio_forge_page.dart'; // <-- IMPORT DE LA BIO-FORGE
// import 'laboratoire_rd_page.dart';
// import 'archives_guerre_page.dart';


class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtient l'instance de AuthService via le provider pour la déconnexion
    final authService = ref.watch(authServiceProvider);

    // Regarde l'état d'authentification pour obtenir l'utilisateur connecté (AsyncValue)
    final authState = ref.watch(authStateChangesProvider);

    // Regarde les données de ressources de l'utilisateur via userResourcesProvider.
    final userResources = ref.watch(userResourcesProvider);

    // Obtient l'AsyncValue du profil complet (dont dépendent les ressources) pour gérer son loading/error state
    final userProfileAsyncValue = ref.watch(userProfileProvider);


    // Obtient l'instance de FirestoreService (Provider)
    final firestoreService = ref.watch(firestoreServiceProvider);


    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de Bord Immunitaire')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bienvenue Cyber-Guerrier !', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),

            // **AFFICHAGE DE L'EMAIL DE L'UTILISATEUR**
            authState.when(
              data: (user) {
                if (user != null && user.email != null) {
                  return Text('Connecté en tant que : ${user.email!}');
                }
                return const SizedBox.shrink();
              },
              loading: () => const Text('Vérification de l\'utilisateur...'),
              error: (err, stack) => Text('Erreur utilisateur : $err'),
            ),

            const SizedBox(height: 20),

            // **AFFICHAGE DES RESSOURCES :** Gère la valeur potentiellement null de userResources
            const Text('Vos Ressources :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            if (userResources != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Énergie : ${userResources.energie.toStringAsFixed(1)}'),
                  Text('Bio-matériaux : ${userResources.bioMateriaux.toStringAsFixed(1)}'),
                ],
              )
            else
              userProfileAsyncValue.when(
                data: (_) => const Text('Ressources non disponibles.'),
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => Text('Erreur de chargement des ressources : $err'),
              ),


            const SizedBox(height: 20),

            // **Bouton temporaire pour Sauvegarder une Base Exemple**
            ElevatedButton(
              onPressed: () async {
                final currentUser = ref.read(authStateChangesProvider).value;

                if (currentUser == null) {
                  print('Impossible de sauvegarder la base : utilisateur non connecté.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Impossible de sauvegarder : connectez-vous d\'abord.')),
                  );
                  return;
                }

                final currentContext = context;
                final currentUserRef = ref;

                final baseExemple = BaseVirale(
                  id: currentUser.uid,
                  nom: 'Base de ${currentUser.email?.split('@').first ?? 'CyberGuerrier'}',
                  createurId: currentUser.uid,
                  pathogenes: [
                    Virus(id: const Uuid().v4(), pv: 50.0, maxPv: 50.0, armure: 5.0, typeAttaque: 'corrosive', degats: 10.0, initiative: 15, faiblesses: {'physique': 1.5, 'energetique': 0.5}),
                    Virus(id: const Uuid().v4(), pv: 60.0, maxPv: 60.0, armure: 8.0, typeAttaque: 'perforante', degats: 12.0, initiative: 12, faiblesses: {'chimique': 1.5}),
                    Bacterie(id: const Uuid().v4(), pv: 100.0, maxPv: 100.0, armure: 10.0, typeAttaque: 'physique', degats: 8.0, initiative: 10, faiblesses: {'energetique': 1.5, 'physique': 0.8}),
                  ],
                );

                await firestoreService.savePlayerBase(userId: currentUser.uid, base: baseExemple);

                if (!currentUserRef.context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(currentContext).showSnackBar(
                  const SnackBar(content: Text('Base virale exemple sauvegardée !')),
                );
                print('Base virale exemple sauvegardée pour ${currentUser.uid}');

              },
              child: const Text('Sauvegarder ma Base (Exemple)'),
            ),

            const SizedBox(height: 20),

            // Bouton de Déconnexion
            ElevatedButton(
              onPressed: () async {
                final currentContext = context;
                final currentUserRef = ref;
                await authService.signOut();
                if (!currentUserRef.context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  const SnackBar(content: Text('Déconnexion réussie !')),
                );
              },
              child: const Text('Déconnexion'),
            ),

            const SizedBox(height: 20),

            // --- Boutons de Navigation vers les autres sections ---
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerPage()));
              },
              child: const Text('Scanner de Menaces'),
            ),
            // DÉCOMMENTE CE BOUTON POUR LA BIO-FORGE
            ElevatedButton(
              onPressed: () {
                // Navigue vers la page Bio-Forge
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BioForgePage())); // <-- NAVIGUE VERS LA BIO-FORGE
              },
              child: const Text('Bio-Forge (Gérer ma Base)'),
            ),
            // ElevatedButton(
            //   onPressed: () {
            //      print("TODO: Naviguer vers le Laboratoire R&D");
            //   },
            //   child: const Text('Laboratoire R&D'),
            // ),
            // ElevatedButton(
            //   onPressed: () {
            //      print("TODO: Naviguer vers les Archives de Guerre");
            //   },
            //   child: const Text('Archives de Guerre'),
            // ),
            // ElevatedButton(
            //    onPressed: () {
            //       print("TODO: Lancer un Combat (Simulateur)");
            //    },
            //    child: const Text('Lancer un Combat (Simulateur)'),
            //  ),

          ],
        ),
      ),
    );
  }
}