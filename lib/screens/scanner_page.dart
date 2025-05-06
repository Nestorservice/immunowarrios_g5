import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/auth_state_provider.dart'; // Importe nos providers (y compris allViralBasesProvider)
import '../models/base_virale.dart'; // Importe le modèle BaseVirale
import 'base_details_page.dart'; // <-- IMPORT DE LA PAGE DE DÉTAILS

class ScannerPage extends ConsumerWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Regarde la liste de toutes les bases virales via le provider.
    final viralBasesAsyncValue = ref.watch(allViralBasesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scanner de Menaces')),
      body: viralBasesAsyncValue.when(
        // Quand la liste des bases est prête
        data: (bases) {
          if (bases.isEmpty) {
            return const Center(child: Text('Aucune base virale détectée pour l\'instant.'));
          }
          // Affiche la liste des bases virales
          return ListView.builder(
            itemCount: bases.length,
            itemBuilder: (context, index) {
              final base = bases[index];
              // TODO: Améliorer l'affichage de chaque élément de la liste
              return ListTile(
                title: Text(base.nom ?? 'Base sans nom'),
                subtitle: Text('Créateur : ${base.createurId} (${base.pathogenes.length} pathogènes)'),
                onTap: () {
                  // Naviguer vers la page de détails de la base, en passant l'ID de la base
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BaseDetailsPage(baseId: base.id), // <-- NAVIGUE VERS LA PAGE DE DÉTAILS
                    ),
                  );
                },
              );
            },
          );
        },
        // Pendant le chargement
        loading: () => const Center(child: CircularProgressIndicator()),
        // En cas d'erreur
        error: (err, stack) => Center(child: Text('Erreur de scan : $err')),
      ),
    );
  }
}