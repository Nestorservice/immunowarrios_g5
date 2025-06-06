import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart'; // Importe Google Fonts

import '../state/auth_state_provider.dart'; // Importe nos providers
import '../models/base_virale.dart'; // Importe le modèle BaseVirale
import '../services/firestore_service.dart'; // Importe le FirestoreService
import 'base_details_page.dart'; // Assurez-vous que cette page existe si vous la gardez
import 'combat_visualization_page.dart'; // La page de visualisation du combat

// --- Palette de couleurs thématique "Immuno-Médical" (clair, propre) ---
// Réutilise les couleurs définies précédemment
const Color hospitalPrimaryGreen = Color(0xFF4CAF50); // Vert Médical (Succès, OK)
const Color hospitalAccentPink = Color(0xFFE91E63); // Rose Vif (Accent, Alerte Menace)
const Color hospitalBackgroundColor = Color(0xFFF5F5F5); // Fond clair principal (Gris très clair)
const Color hospitalCardColor = Color(0xFFFFFFFF); // Fond blanc pour les panneaux / cartes (Propre)
const Color hospitalTextColor = Color(0xFF212121); // Texte sombre sur fond clair (Lecture facile)
const Color hospitalSubTextColor = Color(0xFF757575); // Texte moins important / labels (Gris moyen)
const Color hospitalWarningColor = Color(0xFFF44336); // Rouge (Erreur, Danger)
const Color hospitalErrorColor = Color(0xFFFF9800); // Orange (Avertissement)


// Provider pour toutes les bases virales sauf celle de l'utilisateur connecté
final allBasesProvider = StreamProvider.autoDispose<List<BaseVirale>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  return authState.when(
    data: (user) {
      if (user != null) {
        // CORRECTION ICI : Appel à streamAllOtherViralBases avec l'ID de l'utilisateur
        return firestoreService.streamAllOtherViralBases(user.uid);
      }
      return Stream.value([]); // Retourne un stream vide si pas d'utilisateur connecté
    },
    loading: () => Stream.value([]), // Retourne un stream vide pendant le chargement
    error: (err, stack) => Stream.error(err), // Retourne une erreur en cas de problème
  );
});

// Provider pour la base virale de l'utilisateur (sera utilisé pour le combat)
final playerBaseProvider = StreamProvider.autoDispose<BaseVirale?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.when(
    data: (user) {
      if (user != null) {
        final firestoreService = ref.watch(firestoreServiceProvider);
        return firestoreService.streamViralBase(user.uid);
      }
      return Stream.value(null);
    },
    loading: () => Stream.value(null),
    error: (err, stack) => Stream.value(null),
  );
});


class ScannerPage extends ConsumerWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoute le stream des bases virales (autres que celle de l'utilisateur)
    final basesAsyncValue = ref.watch(allBasesProvider);
    // Écoute le stream de la base virale du joueur
    final playerBaseAsyncValue = ref.watch(playerBaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Diagnostic Viral',
          style: GoogleFonts.poppins(
            color: hospitalTextColor, // Texte sombre
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: hospitalBackgroundColor, // Fond clair
        elevation: 1.0, // Petite ombre
        centerTitle: true,
      ),
      backgroundColor: hospitalBackgroundColor, // Fond de la page
      body: basesAsyncValue.when(
        // Quand les données sont disponibles
        data: (bases) {
          if (bases.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, size: 60, color: hospitalSubTextColor),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun échantillon de base virale à scanner actuellement.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(fontSize: 18, color: hospitalSubTextColor),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Créez la vôtre dans la Bio-Forge, ou attendez que d\'autres joueurs en créent !',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(fontSize: 14, color: hospitalSubTextColor.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            );
          }

          // Affiche la liste des bases virales (autres que la sienne)
          return ListView.builder(
            padding: const EdgeInsets.all(16.0), // Marge autour de la liste
            itemCount: bases.length,
            itemBuilder: (context, index) {
              final base = bases[index];
              return Card(
                color: hospitalCardColor, // Fond blanc pour les cartes
                margin: const EdgeInsets.symmetric(vertical: 8.0), // Marge verticale entre les cartes
                elevation: 3.0, // Ombre légère pour effet de profondeur
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0), // Bords arrondis
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10.0),
                  onTap: () async {
                    // Récupère la base du joueur de manière synchrone (une fois)
                    // Utilise .value pour obtenir la dernière valeur du StreamProvider
                    final playerBase = playerBaseAsyncValue.value;

                    if (playerBase == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Votre équipe immunitaire n\'est pas prête. Veuillez la créer dans la Bio-Forge.'),
                          backgroundColor: hospitalWarningColor,
                        ),
                      );
                      return;
                    }

                    if (playerBase.pathogenes.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Votre équipe immunitaire est vide ! Créez des pathogènes dans la Bio-Forge.'),
                          backgroundColor: hospitalWarningColor,
                        ),
                      );
                      return;
                    }

                    // Navigue vers la page de visualisation du combat
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CombatVisualizationPage(
                          playerBase: playerBase,
                          enemyBase: base, // La base sélectionnée est la base ennemie
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Icône ou avatar (peut être amélioré avec une image plus tard)
                        Icon(Icons.bug_report, size: 40, color: hospitalAccentPink), // Icône de bug, rose vif
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                base.nom ?? 'Base Inconnue', // Nom de la base, police Poppins, gras
                                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: hospitalTextColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Créateur : ${base.createurId.substring(0, 6)}... | Contaminants : ${base.pathogenes.length}', // Texte adapté
                                style: GoogleFonts.roboto(fontSize: 14, color: hospitalSubTextColor), // Police standard, gris moyen
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Icône de navigation
                        Icon(Icons.arrow_forward_ios, size: 18, color: hospitalSubTextColor.withOpacity(0.7)), // Gris avec opacité
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        // Pendant le chargement (Centré avec indicateur stylisé)
        loading: () => Center(child: CircularProgressIndicator(color: hospitalPrimaryGreen)), // Indicateur vert
        // En cas d'erreur (Centré avec texte stylisé)
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Erreur lors de l\'analyse : ${err.toString()}', // Message adapté
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(color: hospitalErrorColor, fontSize: 16), // Police standard, rouge erreur
            ),
          ),
        ),
      ),
    );
  }
}