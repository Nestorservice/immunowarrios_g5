import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/auth_state_provider.dart'; // Importe les providers si besoin
import '../models/base_virale.dart'; // Importe le modèle BaseVirale

// Ce provider va regarder une seule base virale basée sur son ID.
// On utilise un "Family" provider parce qu'il dépend d'un argument (l'ID de la base).
// Il regarde userProfileProvider pour l'UID de l'utilisateur (pour l'accès Firestore)
// et utilise firestoreServiceProvider pour interagir avec Firestore.
final baseDetailsProvider = StreamProvider.autoDispose.family<BaseVirale?, String>((ref, baseId) {
  // Obtient le service Firestore
  final firestoreService = ref.watch(firestoreServiceProvider);

  // Écoute le stream de la base virale spécifique
  // streamViralBase(baseId) devrait exister dans FirestoreService (nous l'avons créé en Étape 4)
  return firestoreService.streamViralBase(baseId); // Assure-toi que cette méthode existe et retourne un Stream<BaseVirale?>
});


class BaseDetailsPage extends ConsumerWidget {
  // La page a besoin de l'ID de la base à afficher
  final String baseId;

  const BaseDetailsPage({super.key, required this.baseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Regarde les détails de la base virale via le provider Family, en lui passant l'ID
    final baseDetailsAsyncValue = ref.watch(baseDetailsProvider(baseId)); // Passe l'ID au provider Family

    return Scaffold(
      appBar: AppBar(title: const Text('Détails de la Base')),
      body: baseDetailsAsyncValue.when(
        // Quand les données de la base sont prêtes
        data: (base) {
          if (base == null) {
            // Si la base n'est pas trouvée (ID invalide, permissions, etc.)
            return const Center(child: Text('Base virale introuvable.'));
          }
          // Si la base est trouvée, affiche ses détails
          return SingleChildScrollView( // Pour pouvoir scroller si beaucoup de pathogènes
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nom de la Base : ${base.nom ?? 'Base sans nom'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Créateur : ${base.createurId}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                const Text('Pathogènes détectés :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

                // Affiche la liste des pathogènes dans la base
                if (base.pathogenes.isEmpty)
                  const Text('Cette base ne contient aucun pathogène pour l\'instant.')
                else
                  ListView.builder(
                    shrinkWrap: true, // Indispensable dans un Column/SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(), // Pour désactiver le scroll de la liste imbriquée
                    itemCount: base.pathogenes.length,
                    itemBuilder: (context, index) {
                      final pathogene = base.pathogenes[index];
                      // TODO: Améliorer l'affichage des détails du pathogène
                      return ListTile(
                        title: Text('Type : ${pathogene.type}'),
                        subtitle: Text('PV : ${pathogene.pv.toStringAsFixed(1)} / ${pathogene.maxPv.toStringAsFixed(1)}'),
                        // Tu peux ajouter plus de détails ici (armure, dégâts, etc.)
                      );
                    },
                  ),

                const SizedBox(height: 20),

                // TODO: Ajouter un bouton "Lancer le Combat" ici (Étape 9)
                // ElevatedButton(
                //   onPressed: () {
                //     // TODO: Naviguer vers la page de combat en passant l'ID de cette base
                //     print('TODO: Lancer le combat contre la base ${base.id}');
                //   },
                //   child: const Text('Lancer le Combat'),
                // ),
              ],
            ),
          );
        },
        // Pendant le chargement des détails de la base
        loading: () => const Center(child: CircularProgressIndicator()),
        // En cas d'erreur lors du chargement
        error: (err, stack) => Center(child: Text('Erreur lors du chargement de la base : $err')),
      ),
    );
  }
}