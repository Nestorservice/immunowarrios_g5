import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // Nécessaire pour générer des ID uniques pour les nouveaux pathogènes
import '../models/base_virale.dart';
// Importe les modèles spécifiques dont on aura besoin pour les types (même si non directement utilisés dans le code, bonne pratique)
import '../models/ressources_defensives.dart';
import '../models/laboratoire_recherche.dart';
import '../models/memoire_immunitaire.dart';
import '../models/agent_pathogene.dart'; // Assure-toi que ce modèle existe
// Importe les classes spécifiques des pathogènes si tu les utilises directement (comme Virus dans _addPathogen)
import '../models/virus.dart'; // Exemple : si tu ajoutes des Virus
import '../models/bacterie.dart'; // Exemple : si tu ajoutes des Bactéries
// import '../models/champignon.dart'; // Exemple : si tu utilises Champignons

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

  // Fonction pour retirer un pathogène de la base du joueur et sauvegarder
  // Cette fonction est définie À L'INTÉRIEUR de la classe BioForgePage
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


  // Fonction pour ajouter un pathogène à la base du joueur et sauvegarder
  // Cette fonction est définie À L'INTÉRIEUR de la classe BioForgePage
  void _addPathogen(WidgetRef ref, BaseVirale currentBase) async {
    // Obtenir l'utilisateur connecté pour avoir l'UID
    final currentUser = ref.read(authStateChangesProvider).value;
    if (currentUser == null) {
      print('Impossible d\'ajouter le pathogène : utilisateur non connecté.');
      // Optionnel : afficher un message à l'utilisateur
      return;
    }
    final userId = currentUser.uid;

    // **Créer un nouveau pathogène exemple (par exemple, un Virus simple)**
    // Utilise Uuid().v4() pour générer un ID unique pour le nouveau pathogène
    final newPathogen = Virus( // <-- Choisis le type de pathogène à ajouter ici (Virus, Bacterie, Champignon)
      id: const Uuid().v4(), // ID unique généré
      pv: 30.0, // Points de vie initiaux
      maxPv: 30.0, // Points de vie maximum
      armure: 3.0,
      typeAttaque: 'acide', // Exemple de type d'attaque
      degats: 5.0, // Dégâts de base
      initiative: 8,
      faiblesses: {'physique': 1.2, 'chimique': 0.8}, // Exemples de faiblesses
      // Ajoute d'autres propriétés spécifiques à ce type de pathogène si nécessaire
    );

    // Créer une nouvelle liste de pathogènes en ajoutant le nouveau
    // Utilise spread operator (...) pour copier les pathogènes existants et ajouter le nouveau
    final updatedPathogensList = [...currentBase.pathogenes, newPathogen];

    // Créer un nouvel objet BaseVirale avec la liste de pathogènes mise à jour
    final updatedBase = BaseVirale(
      id: currentBase.id, // L'ID ne change pas (c'est l'UID du joueur)
      nom: currentBase.nom, // Le nom ne change pas
      createurId: currentBase.createurId, // Le créateur ne change pas
      pathogenes: updatedPathogensList, // La nouvelle liste de pathogènes
      // Copie les autres propriétés si ta classe BaseVirale en a d'autres
    );

    // Obtenir l'instance du service Firestore
    final firestoreService = ref.read(firestoreServiceProvider);

    // Appeler la méthode de sauvegarde
    try {
      await firestoreService.savePlayerBase(userId: userId, base: updatedBase);
      print('Nouveau pathogène ${newPathogen.id} (${newPathogen.type}) ajouté et base sauvegardée pour $userId.');
      // Optionnel : afficher un message de succès à l'utilisateur
    } catch (e) {
      print('Erreur lors de l\'ajout du pathogène ou de la sauvegarde : $e');
      // Optionnel : afficher un message d'erreur à l'utilisateur
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Regarde le provider parent (userProfileProvider) pour gérer l'état global du profil
    final userProfileAsyncValue = ref.watch(userProfileProvider);

    // Regarde la base virale du joueur via le playerBaseProvider (retourne un AsyncValue<BaseVirale?>)
    final playerBaseAsyncValue = ref.watch(playerBaseProvider);


    return Scaffold(
      appBar: AppBar(title: const Text('Bio-Forge')),
      // Utilise .when() sur le userProfileAsyncValue pour gérer les états de chargement/erreur globaux du profil
      body: userProfileAsyncValue.when(
        // Quand les données du profil utilisateur sont chargées (profileData est Map<String, dynamic>? ou null)
        data: (profileData) {
          // Si le profilData est null (ex: pas connecté, ou document non trouvé), affiche un message global
          if (profileData == null) {
            return const Center(child: Text('Profil utilisateur non disponible. Veuillez vous connecter.'));
          }

          // Si profileData est disponible, alors les providers dérivés (ressources, recherche, mémoire)
          // ont été mis à jour avec les données du profil.
          // Maintenant, on regarde les valeurs fournies par ces providers.
          // Ces variables contiennent une VALEUR (qui peut être null), PAS un AsyncValue.
          final RessourcesDefensives? userResources = ref.watch(userResourcesProvider);
          final LaboratoireRecherche? userResearch = ref.watch(userResearchProvider);
          final MemoireImmunitaire? userImmuneMemory = ref.watch(userImmuneMemoryProvider);


          // Maintenant que le profil global est chargé, on construit le corps de la page.
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Votre Centre d\'Opérations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // --- Affichage des Ressources ---
                const Text('Vos Ressources :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                // Vérifie si userResources est null directement
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
                // Vérifie si userResearch est null directement
                if (userResearch != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Points de Recherche : ${userResearch.pointsRecherche.toStringAsFixed(1)}'),
                      // **CORRECTION DE TYPO :** Utilise userResearch ici, pas research
                      Text('Recherches Débloquées : ${userResearch.recherchesDebloquees.join(', ') }'),
                    ],
                  )
                else
                  const Text('Laboratoire R&D non disponible.'),

                const SizedBox(height: 20),

                // --- Affichage de la Mémoire Immunitaire ---
                const Text('Votre Mémoire Immunitaire :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                // Vérifie si userImmuneMemory est null directement
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
                            shrinkWrap: true, // Indispensable dans un Column/SingleChildScrollView
                            physics: const NeverScrollableScrollPhysics(), // Pour désactiver le scroll de la liste imbriquée
                            itemCount: playerBase.pathogenes.length,
                            itemBuilder: (context, index) {
                              final pathogene = playerBase.pathogenes[index];
                              // TODO: Améliorer l'affichage des détails du pathogène
                              return ListTile(
                                title: Text('Type : ${pathogene.type}'),
                                subtitle: Text('PV : ${pathogene.pv.toStringAsFixed(1)} / ${pathogene.maxPv.toStringAsFixed(1)}'),
                                // Ajouter d'autres détails du pathogène si pertinent

                                // Bouton Retirer
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  tooltip: 'Retirer ce pathogène',
                                  onPressed: () {
                                    print('Tentative de retrait du pathogène ${pathogene.id} (${pathogene.type})');
                                    // Appelle la fonction pour retirer le pathogène
                                    _removePathogen(ref, playerBase, pathogene.id);
                                  },
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 20),

                        // Bouton Ajouter un Pathogène
                        ElevatedButton(
                          onPressed: () {
                            print('Tentative d\'ajout d\'un pathogène');
                            // Appelle la fonction pour ajouter le pathogène
                            _addPathogen(ref, playerBase);
                          },
                          child: const Text('Ajouter un Pathogène'),
                        )

                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Erreur de chargement de votre base : $err'),
                ),


                const SizedBox(height: 20),

                // TODO: Ajouter d'autres sections de la Bio-Forge si besoin (ex: Inventaire de pathogènes non utilisés)

              ],
            ),
          );
        },
        // Gère l'état de chargement global du profil
        loading: () => const Center(child: CircularProgressIndicator(key: ValueKey('profileLoading'))),
        // Gère l'état d'erreur global du profil
        error: (err, stack) => Center(child: Text('Erreur lors du chargement du profil utilisateur : $err')),
      ),
    );
  }

} // Fin de la classe BioForgePage