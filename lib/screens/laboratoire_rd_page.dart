import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/auth_state_provider.dart';
import '../models/laboratoire_recherche.dart';

// Définition simple d'une recherche
class ResearchOption {
  final String id; // Identifiant unique
  final String name;
  final String description;
  final double cost; // Coût en points de recherche
  // TODO: Ajouter d'autres propriétés comme les pré-requis, les effets (plus tard)

  const ResearchOption({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
  });
}

// Liste de toutes les recherches disponibles dans le jeu
const List<ResearchOption> availableResearchOptions = [
  ResearchOption(
    id: 'viral_upgrade_1',
    name: 'Amélioration Virale Niv. 1',
    description: 'Augmente les PV de base des Virus.',
    cost: 50.0,
  ),
  ResearchOption(
    id: 'bacterial_armor_1',
    name: 'Armure Bactérienne Niv. 1',
    description: 'Augmente l\'armure de base des Bactéries.',
    cost: 75.0,
  ),
  // Ajoute d'autres recherches ici
];

class LaboratoireRDPage extends ConsumerWidget {
  const LaboratoireRDPage({super.key});

  // Fonction pour débloquer une recherche.
  // **CORRECTION :** Ajoute BuildContext context comme premier paramètre.
  void _unlockResearch(BuildContext context, WidgetRef ref, LaboratoireRecherche currentResearch, ResearchOption researchToUnlock) async {
    // Obtenir l'utilisateur connecté pour avoir l'UID
    final currentUser = ref.read(authStateChangesProvider).value;
    if (currentUser == null) {
      print('Impossible de débloquer la recherche : utilisateur non connecté.');
      // Utilise le context maintenant disponible
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour débloquer des recherches.')),
      );
      return;
    }
    final userId = currentUser.uid;

    // Vérifier si déjà débloquée (double vérification, l'interface gère déjà le bouton)
    if (currentResearch.recherchesDebloquees.contains(researchToUnlock.id)) {
      print('Recherche déjà débloquée.');
      // Utilise le context maintenant disponible
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cette recherche est déjà débloquée.')),
      );
      return;
    }

    // Vérifier si assez de points
    if (currentResearch.pointsRecherche < researchToUnlock.cost) {
      print('Points de recherche insuffisants.');
      // Utilise le context maintenant disponible
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Points de recherche insuffisants. Coût : ${researchToUnlock.cost.toStringAsFixed(1)}.')), // Ajoute .toStringAsFixed(1) pour le format
      );
      return;
    }

    // Si toutes les vérifications sont bonnes :
    // 1. Soustraire les points
    final double updatedPoints = currentResearch.pointsRecherche - researchToUnlock.cost;

    // 2. Ajouter la recherche à la liste des recherches débloquées
    // Crée une nouvelle liste car List<String> est immuable
    final List<String> updatedResearchesDebloquees = List.from(currentResearch.recherchesDebloquees)..add(researchToUnlock.id);


    // 3. Préparer les données à mettre à jour dans Firestore
    // On met à jour *seulement* le champ 'research' du document utilisateur.
    final updatedResearchMap = LaboratoireRecherche(
      pointsRecherche: updatedPoints,
      recherchesDebloquees: updatedResearchesDebloquees,
    ).toJson();


    // 4. Appeler le service Firestore pour mettre à jour le document utilisateur
    final firestoreService = ref.read(firestoreServiceProvider);

    try {
      // Utilise updateUserProfile pour mettre à jour seulement le champ 'research'
      await firestoreService.updateUserProfile(userId, {'research': updatedResearchMap});
      print('Recherche "${researchToUnlock.name}" débloquée pour $userId.');
      // Utilise le context maintenant disponible
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recherche "${researchToUnlock.name}" débloquée !')),
      );
    } catch (e) {
      print('Erreur lors du déblocage de la recherche ou de la sauvegarde : $e');
      // Utilise le context maintenant disponible
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du déblocage de la recherche : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) { // <-- context est disponible ici
    final LaboratoireRecherche? userResearch = ref.watch(userResearchProvider);
    final userProfileAsyncValue = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Laboratoire R&D')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Votre Centre de Recherche et Développement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Progression actuelle :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            userProfileAsyncValue.when(
              data: (profileData) {
                // userResearch est lu ici, dans la portée où profileData a été traité par le provider.
                // On affiche les détails R&D seulement si userResearch n'est pas null
                if (userResearch == null) {
                  return const Text('Données R&D non disponibles.');
                }

                return Column( // Regroupe l'affichage des détails R&D si userResearch n'est pas null
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Points de Recherche : ${userResearch.pointsRecherche.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Recherches Débloquées :',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    if (userResearch.recherchesDebloquees.isEmpty)
                      const Text('Aucune recherche débloquée pour l\'instant.')
                    else
                    // Utilise le spread operator pour ajouter la liste de Widgets Text des recherches débloquées
                      ...userResearch.recherchesDebloquees
                          .map((recherche) => Text('- $recherche'))
                          .toList(),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) =>
                  Text('Erreur de chargement R&D : $err'),
            ),
            const SizedBox(height: 30),

            // --- Section Futures Recherches ---
            const Text('Recherches disponibles :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            // Affichage dynamique des recherches disponibles
            // On affiche cette liste seulement si userResearch (données R&D) est disponible
            if (userResearch != null) // Affiche cette section seulement si les données de recherche sont disponibles
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: availableResearchOptions.length,
                itemBuilder: (context, index) { // <-- context est disponible ici dans le builder
                  final research = availableResearchOptions[index];

                  final bool isUnlocked = userResearch.recherchesDebloquees.contains(research.id);
                  final bool canAfford = userResearch.pointsRecherche >= research.cost;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(research.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(research.description),
                          const SizedBox(height: 8),
                          Text(
                            'Coût : ${research.cost.toStringAsFixed(1)} Points de Recherche',
                            style: TextStyle(
                              color: canAfford ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Bouton Débloquer
                          ElevatedButton(
                            // Le bouton est actif seulement si PAS débloqué ET peut payer
                            onPressed: isUnlocked ? null : (canAfford ? () {
                              print('Tentative de débloquer : ${research.name}');
                              // **CORRECTION :** Passe le context ici à _unlockResearch
                              _unlockResearch(context, ref, userResearch, research);
                            } : null), // Désactive si déjà débloqué ou ne peut pas payer

                            child: Text(isUnlocked ? 'Débloqué' : 'Débloquer'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              const Text('Chargement des recherches disponibles...'), // Message si userResearch est null (pendant chargement global du profil)


            // TODO: Ajouter d'autres sections du Laboratoire R&D
          ],
        ),
      ),
    );
  }
}