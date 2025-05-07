import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart'; // Importe Google Fonts

import '../state/auth_state_provider.dart'; // Importe les providers si besoin
import '../models/base_virale.dart'; // Importe le modèle BaseVirale
// Assure-toi que AgentPathogene est importé si tu y accèdes directement (comme pathogene.type)
import '../models/agent_pathogene.dart'; // Importe le modèle AgentPathogene si nécessaire

import 'combat_page.dart'; // <-- AJOUTE CET IMPORT POUR LA PAGE DE COMBAT
// Importe FirestoreService pour baseDetailsProvider
import '../services/firestore_service.dart';


// --- Palette de couleurs thématique "Immuno-Médical" ---
// Réutilise les couleurs
const Color hospitalPrimaryGreen = Color(0xFF4CAF50); // Vert Médical (OK, Succès)
const Color hospitalAccentPink = Color(0xFFE91E63); // Rose Vif (Accent, Alerte, Danger potentiel)
const Color hospitalBackgroundColor = Color(0xFFF5F5F5); // Fond clair principal
const Color hospitalCardColor = Color(0xFFFFFFFF); // Fond blanc carte
const Color hospitalTextColor = Color(0xFF212121); // Texte sombre
const Color hospitalSubTextColor = Color(0xFF757575); // Texte gris
const Color hospitalWarningColor = Color(0xFFFF9800); // Orange (Avertissement)
const Color hospitalErrorColor = Color(0xFFF44336); // Rouge Vif (Erreur)


// Ce provider va regarder une seule base virale basée sur son ID.
// On utilise un "Family" provider parce qu'il dépend d'un argument (l'ID de la base).
// Il dépend de firestoreServiceProvider.
final baseDetailsProvider = StreamProvider.autoDispose.family<BaseVirale?, String>((ref, baseId) {
  // Obtient le service Firestore
  final firestoreService = ref.watch(firestoreServiceProvider);

  // Écoute le stream de la base virale spécifique
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
      // AppBar stylisée pour l'analyse de menace
      appBar: AppBar(
        title: Text('Dossier Pathogène', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), // Titre adapté, police propre
        backgroundColor: hospitalAccentPink, // Rose vif pour indiquer une analyse de menace
        elevation: 1.0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // Icônes blanches
      ),
      backgroundColor: hospitalBackgroundColor, // Fond clair
      body: baseDetailsAsyncValue.when(
        // Chargement des détails de la base
        loading: () => Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: hospitalAccentPink), // Indicateur rose vif
            const SizedBox(height: 16),
            Text('Analyse de l\'échantillon...', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic)),
          ],
        )),
        // Erreur lors du chargement
        error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('Erreur lors de l\'analyse de l\'échantillon : ${err.toString()}', textAlign: TextAlign.center, style: GoogleFonts.roboto(color: hospitalErrorColor, fontSize: 16)), // Texte erreur rouge
            )),
        // Données de la base chargées
        data: (base) {
          if (base == null) {
            // Si la base n'est pas trouvée
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.find_in_page_outlined, size: 60, color: hospitalSubTextColor),
                    const SizedBox(height: 16),
                    Text(
                      'Échantillon pathogène introuvable.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(fontSize: 18, color: hospitalSubTextColor),
                    ),
                  ],
                ),
              ),
            );
          }
          // Si la base est trouvée, affiche ses détails dans un panneau stylisé
          return SingleChildScrollView( // Pour pouvoir scroller
            padding: const EdgeInsets.all(20.0), // Padding général
            child: Card( // Enveloppe tout le contenu principal dans une carte
              color: hospitalCardColor, // Fond blanc de la carte
              elevation: 2.0, // Légère ombre
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Coins arrondis
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Padding intérieur de la carte
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre du panneau de détails
                    Text(
                      'Détails de l\'Échantillon', // Titre adapté
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: hospitalTextColor, // Texte sombre
                      ),
                    ),
                    const Divider(color: hospitalSubTextColor, height: 25, thickness: 0.5), // Ligne de séparation


                    // Nom de la Base
                    Row(
                      children: [
                        Icon(Icons.assignment_outlined, size: 24, color: hospitalPrimaryGreen), // Icône dossier/nom
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Nom : ${base.nom ?? 'Base sans nom'}', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: hospitalTextColor), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Créateur
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 24, color: hospitalSubTextColor), // Icône personne
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Créateur : ${base.createurId}', style: GoogleFonts.roboto(fontSize: 15, color: hospitalSubTextColor), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Titre de la liste des pathogènes
                    Text('Contaminants Détectés :', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: hospitalAccentPink)), // Titre adapté, rose vif
                    const SizedBox(height: 8),

                    // Affiche la liste des pathogènes
                    if (base.pathogenes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(child: Text('Cet échantillon ne contient aucun contaminant.', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic))), // Texte adapté
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: base.pathogenes.length,
                        itemBuilder: (context, index) {
                          final pathogene = base.pathogenes[index];
                          // Widget stylisé pour chaque pathogène (similaire à Bio-Forge mais adapté)
                          return _buildPathogenDetailTile(pathogene);
                        },
                      ),

                    const SizedBox(height: 20),

                    // Bouton "Lancer le Combat" (Stylisé)
                    Center( // Centre le bouton
                      child: ElevatedButton.icon( // Bouton avec icône
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hospitalAccentPink, // Fond rose vif pour l'action de combat/analyse
                          foregroundColor: Colors.white, // Texte blanc
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                          elevation: 3.0,
                        ),
                        onPressed: () {
                          print('Lancement de la simulation contre la base ${base.id}');
                          // Navigue vers la page de combat
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CombatPage(enemyBaseId: base.id),
                            ),
                          );
                        },
                        icon: const Icon(Icons.dangerous_outlined), // Icône danger/combat
                        label: Text('Analyser en Simulation', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold)), // Texte adapté
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Widgets helper pour le design (adaptés au thème hospitalier) ---

  // Widget pour afficher les détails d'un pathogène ennemi dans la liste
  Widget _buildPathogenDetailTile(AgentPathogene pathogene) {
    return Card( // Utilise une carte intérieure pour chaque pathogène
      color: hospitalBackgroundColor, // Fond très clair
      elevation: 1.0, // Très légère ombre
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0), // Marge verticale, pas horizontale si déjà dans une carte parent
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Icône pathogène/danger
            Icon(Icons.flare_outlined, size: 28, color: hospitalWarningColor), // Icône évasement/danger, orange
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type et PV
                  Text(
                    'Type : ${pathogene.type}', // Affiche le type
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: hospitalTextColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // PV, Armure, Dégâts (exemple d'autres stats)
                  Text(
                    'PV: ${pathogene.pv.toStringAsFixed(1)} | Armure: ${pathogene.armure.toStringAsFixed(1)} | Dégâts: ${pathogene.degats.toStringAsFixed(1)}',
                    style: GoogleFonts.roboto(fontSize: 14, color: hospitalSubTextColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // TODO: Afficher d'autres stats pertinentes
                ],
              ),
            ),
            // Pas de bouton "Retirer" pour les pathogènes ennemis
          ],
        ),
      ),
    );
  }

} // Fin de la classe BaseDetailsPage