import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // Assure-toi que le package UUID est ajouté et importé
import '../models/bacterie.dart';
import '../models/base_virale.dart';
import '../models/virus.dart';
import '../state/auth_state_provider.dart'; // Importe TOUS nos providers
// Importe les pages pour la navigation future (décommenter quand les pages seront créées)
// import 'scanner_page.dart';
// import 'bio_forge_page.dart';
// import 'laboratoire_rd_page.dart';
// import 'archives_guerre_page.dart';


class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtient l'instance de AuthService via le provider pour la déconnexion
    final authService = ref.watch(authServiceProvider);

    // Regarde l'état d'authentification pour obtenir l'utilisateur connecté (AsyncValue)
    // C'est bien un StreamProvider, donc ref.watch retourne un AsyncValue
    final authState = ref.watch(authStateChangesProvider);

    // Regarde les données de ressources de l'utilisateur via userResourcesProvider.
    // userResourcesProvider est un Provider.autoDispose, donc ref.watch retourne directement la valeur (RessourcesDefensives? ou null).
    // C'est la valeur elle-même qu'on obtient ici.
    final userResources = ref.watch(userResourcesProvider);

    // Obtient l'AsyncValue du profil complet (dont dépendent les ressources) pour gérer son loading/error state
    // userProfileProvider est un StreamProvider, donc ref.watch retourne un AsyncValue.
    // C'est l'AsyncValue parent que l'on utilise pour les états de chargement/erreur globaux du profil.
    final userProfileAsyncValue = ref.watch(userProfileProvider);


    // Obtient l'instance de FirestoreService (Provider) - on pourrait aussi le ref.read() ici si on préfère
    final firestoreService = ref.watch(firestoreServiceProvider);


    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de Bord Immunitaire')),
      body: SingleChildScrollView( // Utilise SingleChildScrollView pour que la page soit scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bienvenue Cyber-Guerrier !', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),

            // **AFFICHAGE DE L'EMAIL DE L'UTILISATEUR**
            // Utilise .when pour gérer l'état de l'AsyncValue de l'authentification
            authState.when(
              data: (user) {
                // Si l'utilisateur est connecté et son email est disponible
                if (user != null && user.email != null) {
                  return Text('Connecté en tant que : ${user.email!}');
                }
                // Sinon (utilisateur null ou email null)
                return const SizedBox.shrink(); // N'affiche rien si l'email n'est pas là
              },
              // Pendant le chargement de l'état d'authentification (très rapide au démarrage)
              loading: () => const Text('Vérification de l\'utilisateur...'),
              // En cas d'erreur de l'état d'authentification
              error: (err, stack) => Text('Erreur utilisateur : $err'),
            ),

            const SizedBox(height: 20),

            // **AFFICHAGE DES RESSOURCES :** Gère la valeur potentiellement null de userResources
            const Text('Vos Ressources :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            // Vérifie si userResources (la valeur directe) est disponible (non null)
            if (userResources != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Énergie : ${userResources.energie.toStringAsFixed(1)}'), // Utilise userResources directement
                  Text('Bio-matériaux : ${userResources.bioMateriaux.toStringAsFixed(1)}'), // Utilise userResources directement
                  // Ajoute d'autres ressources ici si tu en as
                ],
              )
            else
            // Si userResources est null, cela peut être en chargement ou non disponible.
            // On utilise .when sur l'AsyncValue du provider parent (userProfileAsyncValue)
            // pour afficher l'état de chargement ou d'erreur du profil complet.
              userProfileAsyncValue.when( // C'est l'AsyncValue du profil complet qui porte l'état loading/error
                data: (_) => const Text('Ressources non disponibles.'), // Si le profil est chargé mais ressources nulles
                loading: () => const CircularProgressIndicator(), // Si le profil charge
                error: (err, stack) => Text('Erreur de chargement des ressources : $err'), // Si le profil a une erreur
              ),


            const SizedBox(height: 20), // Espace

            // **Bouton temporaire pour Sauvegarder une Base Exemple**
            ElevatedButton(
              onPressed: () async {
                // Utilise ref.read pour obtenir la valeur actuelle du provider SANS écouter les changements
                final currentUser = ref.read(authStateChangesProvider).value; // .value donne User? ou null

                if (currentUser == null) {
                  print('Impossible de sauvegarder la base : utilisateur non connecté.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Impossible de sauvegarder : connectez-vous d\'abord.')),
                  );
                  return;
                }

                // Capture le contexte et la référence Riverpod AVANT l'opération asynchrone
                final currentContext = context;
                final currentUserRef = ref;

                // Crée une base virale exemple avec quelques pathogènes
                // Assure-toi que le package UUID est bien ajouté dans pubspec.yaml et importé
                final baseExemple = BaseVirale(
                  id: currentUser.uid, // Utilise l'UID de l'utilisateur comme ID de la base dans Firestore
                  nom: 'Base de ${currentUser.email?.split('@').first ?? 'CyberGuerrier'}',
                  createurId: currentUser.uid,
                  pathogenes: [
                    Virus(id: const Uuid().v4(), pv: 50.0, maxPv: 50.0, armure: 5.0, typeAttaque: 'corrosive', degats: 10.0, initiative: 15, faiblesses: {'physique': 1.5, 'energetique': 0.5}),
                    Virus(id: const Uuid().v4(), pv: 60.0, maxPv: 60.0, armure: 8.0, typeAttaque: 'perforante', degats: 12.0, initiative: 12, faiblesses: {'chimique': 1.5}),
                    Bacterie(id: const Uuid().v4(), pv: 100.0, maxPv: 100.0, armure: 10.0, typeAttaque: 'physique', degats: 8.0, initiative: 10, faiblesses: {'energetique': 1.5, 'physique': 0.8}),
                  ],
                );

                // Obtient l'instance de FirestoreService via le provider
                // final firestoreService = ref.read(firestoreServiceProvider); // Déjà fait en haut

                // Appelle la méthode de sauvegarde
                await firestoreService.savePlayerBase(userId: currentUser.uid, base: baseExemple);

                // **AJOUT IMPORTANT :** Vérifie si le widget est toujours monté avant de montrer le SnackBar
                if (!currentUserRef.context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(currentContext).showSnackBar( // Utilise le context capturé
                  const SnackBar(content: Text('Base virale exemple sauvegardée !')),
                );
                print('Base virale exemple sauvegardée pour ${currentUser.uid}');

              },
              child: const Text('Sauvegarder ma Base (Exemple)'),
            ),

            const SizedBox(height: 20), // Espace

            // Bouton de Déconnexion
            ElevatedButton(
              onPressed: () async {
                // Capture le contexte et la référence Riverpod AVANT l'opération asynchrone
                final currentContext = context;
                final currentUserRef = ref;

                await authService.signOut();

                // **AJOUT IMPORTANT :** Vérifie si le widget est toujours monté avant de montrer le SnackBar
                if (!currentUserRef.context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(currentContext).showSnackBar( // Utilise le context capturé
                  const SnackBar(content: Text('Déconnexion réussie !')),
                );
              },
              child: const Text('Déconnexion'),
            ),

            const SizedBox(height: 20), // Espace avant les boutons de navigation

            // --- Boutons de Navigation vers les autres sections ---
            // Décommenter et importer les pages quand elles seront prêtes
            ElevatedButton(
              onPressed: () {
                // TODO: S'assurer que la page ScannerPage existe et est importée en haut
                // Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerPage()));
                print("TODO: Naviguer vers le Scanner de Menaces");
              },
              child: const Text('Scanner de Menaces'),
            ),
            // ElevatedButton(
            //   onPressed: () {
            //     // TODO: S'assurer que la page BioForgePage existe et est importée
            //     // Navigator.push(context, MaterialPageRoute(builder: (context) => const BioForgePage()));
            //      print("TODO: Naviguer vers la Bio-Forge");
            //   },
            //   child: const Text('Bio-Forge (Gérer ma Base)'),
            // ),
            // ElevatedButton(
            //   onPressed: () {
            //     // TODO: S'assurer que la page LaboratoireRDPage existe et est importée
            //     // Navigator.push(context, MaterialPageRoute(builder: (context) => const LaboratoireRDPage()));
            //      print("TODO: Naviguer vers le Laboratoire R&D");
            //   },
            //   child: const Text('Laboratoire R&D'),
            // ),
            // ElevatedButton(
            //   onPressed: () {
            //      // TODO: S'assurer que la page ArchivesGuerrePage existe et est importée
            //     // Navigator.push(context, MaterialPageRoute(builder: (context) => const ArchivesGuerrePage()));
            //      print("TODO: Naviguer vers les Archives de Guerre");
            //   },
            //   child: const Text('Archives de Guerre'),
            // ),
            // ElevatedButton(
            //    onPressed: () {
            //       // TODO: Naviguer vers le Simulateur de Combat (peut-être après avoir sélectionné une base ennemie)
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