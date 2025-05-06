import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/base_virale.dart';
// Importe les modèles spécifiques dont on aura besoin pour les types (même si non directement utilisés dans le code, bonne pratique)
import '../models/ressources_defensives.dart';
import '../models/laboratoire_recherche.dart';
import '../models/memoire_immunitaire.dart';
import '../state/auth_state_provider.dart'; // Importe tous nos providers


// Un Provider qui regarde la base virale *du joueur actuellement connecté*.
// Il dépend de authStateChangesProvider (pour l'UID) et utilise streamViralBase.
// Renvoie un Stream<BaseVirale?>.
final playerBaseProvider = StreamProvider.autoDispose<BaseVirale?>((ref) {
  // Regarde l'AsyncValue de l'état d'authentification pour obtenir l'UID
  final authState = ref.watch(authStateChangesProvider);

  // Utilise .when sur l'AsyncValue de l'authentification
  return authState.when(
    data: (user) {
      // Si l'utilisateur est connecté (User n'est pas null)
      if (user != null) {
        final userId = user.uid;
        final firestoreService = ref.watch(firestoreServiceProvider);
        // Retourne le stream de la base virale dont l'ID est l'UID de l'utilisateur
        // streamViralBase(userId) retourne bien un Stream<BaseVirale?>
        return firestoreService.streamViralBase(userId);
      }
      // Si pas connecté, émet un stream qui contient juste null
      return Stream.value(null);
    },
    // Pendant le chargement ou en cas d'erreur de l'auth, émet un stream qui contient juste null
    loading: () => Stream.value(null),
    error: (err, stack) => Stream.value(null),
  );
});


class BioForgePage extends ConsumerWidget {
  const BioForgePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // **CORRECTION :** Regarde le provider parent (userProfileProvider) pour gérer l'état global du profil
    final userProfileAsyncValue = ref.watch(userProfileProvider);

    // Regarde la base virale du joueur via le playerBaseProvider (retourne un AsyncValue<BaseVirale?>)
    final playerBaseAsyncValue = ref.watch(playerBaseProvider);


    return Scaffold(
      appBar: AppBar(title: const Text('Bio-Forge')),
      // **CORRECTION :** Utilise .when() sur le userProfileAsyncValue pour gérer les états de chargement/erreur globaux du profil
      body: userProfileAsyncValue.when(
        // Quand les données du profil utilisateur sont chargées (profileData est Map<String, dynamic>? ou null)
        data: (profileData) {
          // Si le profilData est null (ex: pas connecté, ou document non trouvé), affiche un message global
          if (profileData == null) {
            // On pourrait aussi vérifier l'état de l'auth ici si on voulait un message différent
            // final authState = ref.watch(authStateChangesProvider);
            // if (authState.hasError) return Center(child: Text('Erreur de chargement du profil : ${authState.error}'));
            // if (authState.isLoading) return Center(child: CircularProgressIndicator());
            return const Center(child: Text('Profil utilisateur non disponible. Veuillez vous connecter.'));
          }

          // **CORRECTION :** Si profileData est disponible, alors les providers dérivés (ressources, recherche, mémoire)
          // ont été mis à jour avec les données du profil.
          // Maintenant, on regarde les valeurs fournies par ces providers.
          // Ces variables contiennent une VALEUR (qui peut être null), PAS un AsyncValue.
          final RessourcesDefensives? userResources = ref.watch(userResourcesProvider);
          final LaboratoireRecherche? userResearch = ref.watch(userResearchProvider);
          final MemoireImmunitaire? userImmuneMemory = ref.watch(userImmuneMemoryProvider);


          // **Maintenant que le profil global est chargé, on construit le corps de la page.**
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Votre Centre d\'Opérations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // --- Affichage des Ressources ---
                const Text('Vos Ressources :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                // **CORRECTION :** Vérifie si userResources est null directement
                if (userResources != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Énergie : ${userResources.energie.toStringAsFixed(1)}'),
                      Text('Bio-matériaux : ${userResources.bioMateriaux.toStringAsFixed(1)}'),
                      // Ajoute d'autres ressources si besoin
                    ],
                  )
                else
                  const Text('Ressources non disponibles.'), // Affiche ce message si userResources est null


                const SizedBox(height: 20),

                // --- Affichage de la Recherche ---
                const Text('Votre Laboratoire R&D :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                // **CORRECTION :** Vérifie si userResearch est null directement
                if (userResearch != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Points de Recherche : ${userResearch.pointsRecherche.toStringAsFixed(1)}'),
                      Text('Recherches Débloquées : ${userResearch.recherchesDebloquees.join(', ') }'),
                    ],
                  )
                else
                  const Text('Laboratoire R&D non disponible.'),

                const SizedBox(height: 20),

                // --- Affichage de la Mémoire Immunitaire ---
                const Text('Votre Mémoire Immunitaire :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                // **CORRECTION :** Vérifie si userImmuneMemory est null directement
                if (userImmuneMemory != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Types Pathogènes Connus : ${userImmuneMemory.typesConnus.join(', ') }'),
                      Text('Bonus d\'Efficacité : ${userImmuneMemory.bonusEfficacite.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(1)}').join(', ')}'),
                    ],
                  )
                else
                  const Text('Mémoire Immunitaire non disponible.'),


                const SizedBox(height: 20),

                // --- Affichage de Votre Base Virale ---
                const Text('Votre Base Virale :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                // Continue d'utiliser .when() pour playerBaseAsyncValue car c'est un StreamProvider (retourne un AsyncValue)
                playerBaseAsyncValue.when(
                  data: (playerBase) {
                    if (playerBase == null) {
                      // Si la base du joueur n'existe pas (par exemple, pas encore sauvegardée)
                      return const Text('Aucune base virale personnelle détectée.');
                      // TODO: Ajouter un bouton pour créer la base si elle n'existe pas ?
                    }
                    // Si la base est trouvée, affiche ses détails (principalement les pathogènes)
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nom de la Base : ${playerBase.nom ?? 'Base sans nom'}'),
                        const SizedBox(height: 8),
                        const Text('Pathogènes dans votre base :', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),

                        // Affiche la liste des pathogènes dans la base du joueur
                        if (playerBase.pathogenes.isEmpty)
                          const Text('Votre base ne contient aucun pathogène pour l\'instant.')
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: playerBase.pathogenes.length,
                            itemBuilder: (context, index) {
                              final pathogene = playerBase.pathogenes[index];
                              // TODO: Améliorer l'affichage des détails du pathogène
                              return ListTile(
                                title: Text('Type : ${pathogene.type}'),
                                subtitle: Text('PV : ${pathogene.pv.toStringAsFixed(1)} / ${pathogene.maxPv.toStringAsFixed(1)}'),
                                // Ajouter d'autres détails du pathogène si pertinent

                                // **AJOUT POUR L'ÉTAPE 10.1 : Bouton Retirer**
                                trailing: IconButton( // <-- DÉCOMMENTE OU AJOUTE CE WIDGET
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red), // Utilise une icône rouge pour le retrait
                                  tooltip: 'Retirer ce pathogène', // Ajoute une info-bulle au survol
                                  onPressed: () { // <-- LA LOGIQUE ONPRESSED SERA ICI (Étape 10.2)
                                    print('TODO: Retirer le pathogène ${pathogene.id} (${pathogene.type}) de la base');
                                    // On appellera la fonction pour retirer le pathogène ici
                                    _removePathogen(ref, playerBase, pathogene.id); // Appelle une nouvelle fonction (voir 10.2)
                                  },
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Erreur de chargement de votre base : $err'),
                ),
              ],
            ),
          );
        },
        // **CORRECTION :** Gère l'état de chargement global du profil
        loading: () => const Center(child: CircularProgressIndicator(key: ValueKey('profileLoading'))), // Ajout d'une key optionnelle pour l'exemple
        // **CORRECTION :** Gère l'état d'erreur global du profil
        error: (err, stack) => Center(child: Text('Erreur lors du chargement du profil utilisateur : $err')),
      ),
    );
  }

  // À l'intérieur de la classe BioForgePage { ... }

  // Fonction pour retirer un pathogène de la base du joueur et sauvegarder
  void _removePathogen(WidgetRef ref, BaseVirale currentBase, String pathogenIdToRemove) async {
    // Obtenir l'utilisateur connecté pour avoir l'UID (nécessaire pour la sauvegarde et les règles de sécurité)
    final currentUser = ref.read(authStateChangesProvider).value;
    if (currentUser == null) {
      print('Impossible de retirer le pathogène : utilisateur non connecté.');
      // Optionnel : afficher un message à l'utilisateur
      return;
    }
    final userId = currentUser.uid;

    // Créer une nouvelle liste de pathogènes sans celui à retirer
    // Utilise where().toList() pour créer une nouvelle liste immuable
    final updatedPathogensList = currentBase.pathogenes
        .where((pathogene) => pathogene.id != pathogenIdToRemove)
        .toList();

    // Créer un nouvel objet BaseVirale avec la liste de pathogènes mise à jour
    // C'est important de créer un NOUVEL objet car BaseVirale est final.
    final updatedBase = BaseVirale(
      id: currentBase.id, // L'ID ne change pas
      nom: currentBase.nom, // Le nom ne change pas
      createurId: currentBase.createurId, // Le créateur ne change pas
      pathogenes: updatedPathogensList, // La nouvelle liste de pathogènes
      // Copie les autres propriétés si ta classe BaseVirale en a d'autres et qu'elles ne changent pas
    );

    // Obtenir l'instance du service Firestore
    final firestoreService = ref.read(firestoreServiceProvider);

    // Appeler la méthode de sauvegarde
    try {
      await firestoreService.savePlayerBase(userId: userId, base: updatedBase);
      print('Pathogène $pathogenIdToRemove retiré et base sauvegardée pour $userId.');
      // Optionnel : afficher un message de succès à l'utilisateur
    } catch (e) {
      print('Erreur lors du retrait du pathogène ou de la sauvegarde : $e');
      // Optionnel : afficher un message d'erreur à l'utilisateur
    }
  }

// TODO: Ajouter une fonction _addPathogen similaire pour ajouter des pathogènes
// void _addPathogen(...) async { ... }
}