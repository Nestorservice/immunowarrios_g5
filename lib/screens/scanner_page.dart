import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart'; // Importe Google Fonts

import '../state/auth_state_provider.dart'; // Importe nos providers
import '../models/base_virale.dart'; // Importe le modèle BaseVirale
import 'base_details_page.dart';
// Importe LoginPage si nécessaire pour la navigation (bien que non utilisé directement ici)
// import 'login_page.dart';

// --- Palette de couleurs thématique "Immuno-Médical" (clair, propre) ---
// Réutilise les couleurs définies précédemment
const Color hospitalPrimaryGreen = Color(0xFF4CAF50); // Vert Médical (Succès, OK)
const Color hospitalAccentPink = Color(0xFFE91E63); // Rose Vif (Accent, Alerte Menace)
const Color hospitalBackgroundColor = Color(0xFFF5F5F5); // Fond clair principal (Gris très clair)
const Color hospitalCardColor = Color(0xFFFFFFFF); // Fond blanc pour les panneaux / cartes (Propre)
const Color hospitalTextColor = Color(0xFF212121); // Texte sombre sur fond clair (Lecture facile)
const Color hospitalSubTextColor = Color(0xFF757575); // Texte moins important / labels (Gris moyen)
const Color hospitalWarningColor = Color(0xFFFF9800); // Orange (Avertissement)
const Color hospitalErrorColor = Color(0xFFF44336); // Rouge Vif (Erreur)


class ScannerPage extends ConsumerWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Regarde la liste de toutes les bases virales via le provider.
    final viralBasesAsyncValue = ref.watch(allViralBasesProvider);

    return Scaffold(
      // AppBar thématique claire et propre
      appBar: AppBar(
        title: Text('Analyseur Pathogène', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), // Titre adapté, police propre
        backgroundColor: hospitalPrimaryGreen, // Couleur de fond verte (scanneurs souvent verts)
        elevation: 1.0, // Légère ombre
        centerTitle: true, // Centrer le titre
        iconTheme: const IconThemeData(color: Colors.white), // Icônes (retour) blanches
      ),
      backgroundColor: hospitalBackgroundColor, // Fond très clair pour le corps du Scaffold
      body: viralBasesAsyncValue.when(
        // Quand la liste des bases est prête
        data: (bases) {
          // Filtrer potentiellement la base de l'utilisateur connecté si vous ne voulez pas la scanner
          final currentUser = ref.read(authStateChangesProvider).value;
          final filteredBases = bases.where((base) => currentUser == null || base.createurId != currentUser.uid).toList();


          if (filteredBases.isEmpty) {
            // Message pour l'état vide stylisé (aucune menace)
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 60, color: hospitalPrimaryGreen.withOpacity(0.8)), // Icône verte (OK)
                    const SizedBox(height: 16),
                    Text(
                      'Aucune contamination détectée dans le réseau.\nTous les systèmes sont sûrs.', // Message adapté
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(fontSize: 18, color: hospitalSubTextColor), // Police standard, gris moyen
                    ),
                  ],
                ),
              ),
            );
          }
          // Affiche la liste des bases virales filtrées avec des Cards stylisées
          return ListView.builder(
            padding: const EdgeInsets.all(12.0), // Padding autour de la liste
            itemCount: filteredBases.length,
            itemBuilder: (context, index) {
              final base = filteredBases[index];
              // Utilise un Card pour chaque élément de la liste
              return Card(
                color: hospitalCardColor, // Fond blanc propre pour la carte
                margin: const EdgeInsets.symmetric(vertical: 8.0), // Marge verticale
                elevation: 2.0, // Légère ombre
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Coins légèrement arrondis
                child: InkWell( // Rend la carte tappable
                  borderRadius: BorderRadius.circular(8.0), // Coins pour l'effet d'encre
                  onTap: () {
                    // Naviguer vers la page de détails de la base
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BaseDetailsPage(baseId: base.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0), // Padding intérieur
                    child: Row( // Aligne icône et texte
                      children: [
                        // Icône d'alerte ou de contaminant
                        Icon(
                          base.pathogenes.isNotEmpty ? Icons.warning_amber_outlined : Icons.health_and_safety_outlined, // Icône différente si pathogènes présents ou non
                          size: 40,
                          color: base.pathogenes.isNotEmpty ? hospitalAccentPink : hospitalPrimaryGreen.withOpacity(0.7), // Rose vif si pathogènes (alerte), vert si vide (sain)
                        ),
                        const SizedBox(width: 16), // Espace
                        Expanded( // Permet à la colonne de texte de prendre l'espace restant
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nom de la base virale (Titre)
                              Text(
                                base.nom ?? 'Source Pathogène Inconnue', // Texte adapté
                                style: GoogleFonts.montserrat( // Police pour les titres/noms
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: hospitalTextColor, // Texte sombre
                                ),
                                overflow: TextOverflow.ellipsis, // Empêche le texte de déborder
                              ),
                              const SizedBox(height: 4),
                              // Détails (Sous-titre)
                              Text(
                                'Identifiant : ${base.createurId.substring(0, 6)}... | Contaminants : ${base.pathogenes.length}', // Texte adapté
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