import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/auth_state_provider.dart';
import '../models/laboratoire_recherche.dart';

class LaboratoireRDPage extends ConsumerWidget {
  const LaboratoireRDPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                if (userResearch == null) {
                  return const Text('Données R&D non disponibles.');
                }

                return Column(
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
            const Text(
              'Recherches disponibles :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
                'TODO: Afficher la liste des recherches disponibles ici. Chaque recherche pourrait afficher son coût en points et un bouton pour la débloquer (si le joueur a assez de points).'),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amélioration Virale Niv. 1',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text('Coût : 50 Points de Recherche'),
                    const Text('Effet : Augmente les PV de base des Virus.'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        print(
                            'TODO: Débloquer Amélioration Virale Niv. 1');
                      },
                      child: const Text('Débloquer'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}