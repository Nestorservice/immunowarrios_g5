import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/auth_state_provider.dart'; // Importe TOUS nos providers (y compris allViralBasesProvider)
import '../models/base_virale.dart'; // Importe le modèle BaseVirale

class ScannerPage extends ConsumerWidget { // Utilise ConsumerWidget
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Regarde la liste de toutes les bases virales via le provider.
    // allViralBasesProvider est un StreamProvider, donc ref.watch retourne un AsyncValue<List<BaseVirale>>.
    final viralBasesAsyncValue = ref.watch(allViralBasesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scanner de Menaces')),
      body: viralBasesAsyncValue.when(
        // Quand la liste des bases est prête (AsyncValue a des data)
        data: (bases) {
          // data est ici une List<BaseVirale>
          if (bases.isEmpty) {
            return const Center(child: Text('Aucune base virale détectée pour l\'instant.'));
          }
          // Sinon, affiche la liste des bases virales
          return ListView.builder(
            itemCount: bases.length,
            itemBuilder: (context, index) {
              final base = bases[index];
              // TODO: Améliorer l'affichage de chaque élément de la liste
              return ListTile(
                // Utilise le nom de la base, avec un fallback si le nom est null
                title: Text(base.nom ?? 'Base sans nom'),
                // Utilise le créateur et le nombre de pathogènes
                subtitle: Text('Créateur : ${base.createurId} (${base.pathogenes.length} pathogènes)'),
                // Ajoute une action quand on clique sur la liste
                onTap: () {
                  // TODO: Naviguer vers une page de détails de la base (Étape 8)
                  print('Clic sur la base : ${base.nom}');
                  // Exemple de navigation: Navigator.push(context, MaterialPageRoute(builder: (context) => BaseDetailsPage(baseId: base.id)));
                },
              );
            },
          );
        },
        // Pendant le chargement de la liste des bases (AsyncValue est en état loading)
        loading: () => const Center(child: CircularProgressIndicator()),
        // En cas d'erreur lors du chargement (AsyncValue est en état error)
        error: (err, stack) => Center(child: Text('Erreur de scan : $err')),
      ),
    );
  }
}