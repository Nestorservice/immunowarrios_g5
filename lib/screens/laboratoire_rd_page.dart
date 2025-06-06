// lib/screens/laboratoire_rd_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/auth_state_provider.dart';
import '../models/laboratoire_recherche.dart';
import '../services/firestore_service.dart';


// Définition simple d'une recherche
class ResearchOption {
  final String id; // Identifiant unique
  final String name;
  final String description;
  final double cost; // Coût en points de recherche

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
    description: 'Augmente les PV de base des Virus. Indispensable pour renforcer votre arsenal offensif.',
    cost: 50.0,
  ),
  ResearchOption(
    id: 'bacterial_armor_1',
    name: 'Armure Bactérienne Niv. 1',
    description: 'Augmente l\'armure de base des Bactéries. Renforcez vos défenses de base.',
    cost: 75.0,
  ),
  ResearchOption(
    id: 'energy_efficiency_1',
    name: 'Efficacité Énergétique Niv. 1',
    description: 'Réduit le coût en énergie de certaines opérations.',
    cost: 60.0,
  ),
  ResearchOption(
    id: 'biomaterial_synthesis_1',
    name: 'Synthèse Bio-matériaux Niv. 1',
    description: 'Augmente la production de Bio-matériaux.',
    cost: 80.0,
  ),
  // Ajoute d'autres recherches ici
];

// --- Palette de couleurs thématique "Immuno-Médical" ---
const Color hospitalPrimaryGreen = Color(0xFF4CAF50);
const Color hospitalAccentPink = Color(0xFFE91E63);
const Color hospitalBackgroundColor = Color(0xFFF5F5F5);
const Color hospitalCardColor = Color(0xFFFFFFFF);
const Color hospitalTextColor = Color(0xFF212121);
const Color hospitalSubTextColor = Color(0xFF757575);
const Color hospitalWarningColor = Color(0xFFFF9800);
const Color hospitalErrorColor = Color(0xFFF44336);
const Color hospitalSuccessColor = hospitalPrimaryGreen;


class LaboratoireRDPage extends ConsumerWidget {
  const LaboratoireRDPage({super.key});

  // Fonction pour débloquer une recherche
  void _unlockResearch(BuildContext context, WidgetRef ref, LaboratoireRecherche currentResearch, ResearchOption researchToUnlock) async {
    final currentUser = ref.read(authStateChangesProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Connectez-vous pour débloquer des recherches.'), backgroundColor: hospitalErrorColor),
      );
      return;
    }
    final userId = currentUser.uid;

    if (currentResearch.recherchesDebloquees.contains(researchToUnlock.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Cette recherche est déjà débloquée.'), backgroundColor: hospitalWarningColor),
      );
      return;
    }

    if (currentResearch.pointsRecherche < researchToUnlock.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Points de recherche insuffisants. Coût : ${researchToUnlock.cost.toStringAsFixed(1)}.'), backgroundColor: hospitalWarningColor),
      );
      return;
    }

    // Utilisation de copyWith pour créer un nouvel objet LaboratoireRecherche
    final updatedResearch = currentResearch.copyWith(
      pointsRecherche: currentResearch.pointsRecherche - researchToUnlock.cost,
      recherchesDebloquees: List.from(currentResearch.recherchesDebloquees)..add(researchToUnlock.id),
    );

    final firestoreService = ref.read(firestoreServiceProvider);

    try {
      // Sauvegarde l'objet mis à jour dans Firestore
      await firestoreService.updateUserProfile(userId, {'research': updatedResearch.toJson()});
      print('Recherche "${researchToUnlock.name}" débloquée pour $userId.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recherche "${researchToUnlock.name}" débloquée !'), backgroundColor: hospitalSuccessColor),
      );
    } catch (e) {
      print('Erreur lors du déblocage de la recherche ou de la sauvegarde : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du déblocage de la recherche : ${e.toString()}'), backgroundColor: hospitalErrorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoute les données de recherche de l'utilisateur (peut être null)
    final LaboratoireRecherche? userResearch = ref.watch(userResearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Laboratoire de Recherche',
          style: GoogleFonts.poppins(
            color: hospitalTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: hospitalBackgroundColor,
        elevation: 1.0,
        centerTitle: true,
      ),
      body: Container(
        color: hospitalBackgroundColor,
        child: userResearch == null // Vérifie si userResearch est null
            ? Center( // Affiche un indicateur de chargement ou un message d'attente
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: hospitalPrimaryGreen), // Utilise une couleur cohérente
              const SizedBox(height: 16),
              Text(
                'Préparation du laboratoire...',
                style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        )
            : SingleChildScrollView( // Si userResearch n'est pas null, affiche le contenu complet
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Centre d\'Analyse Biologique',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: hospitalPrimaryGreen,
                ),
              ),
              const SizedBox(height: 30),
              // Panneau d'affichage des points de recherche et des protocoles actifs
              _buildResearchProgressPanel(userResearch), // userResearch est non-null ici
              const SizedBox(height: 40),
              Text(
                'Protocoles de Recherche Disponibles',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: hospitalAccentPink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Liste des recherches disponibles que l'utilisateur peut débloquer
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: availableResearchOptions.length,
                itemBuilder: (context, index) {
                  final researchOption = availableResearchOptions[index];
                  final bool isUnlocked = userResearch.recherchesDebloquees.contains(researchOption.id);
                  final bool canAfford = userResearch.pointsRecherche >= researchOption.cost;

                  return _buildResearchOptionTile(
                    context,
                    ref,
                    userResearch, // userResearch est non-null ici
                    researchOption,
                    isUnlocked,
                    canAfford,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Panneau de Progression R&D (Statistiques de Recherche)
  // Reçoit maintenant un LaboratoireRecherche non-nullable
  Widget _buildResearchProgressPanel(LaboratoireRecherche userResearch) {
    return Card(
      color: hospitalCardColor,
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques de Recherche',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: hospitalPrimaryGreen,
              ),
            ),
            const Divider(color: hospitalSubTextColor, height: 25, thickness: 0.5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Affichage Points de Recherche
                Row(
                  children: [
                    Icon(Icons.analytics_outlined, size: 28, color: hospitalAccentPink),
                    const SizedBox(width: 10),
                    Text(
                      'Points d\'Analyse : ',
                      style: GoogleFonts.roboto(fontSize: 18, color: hospitalSubTextColor),
                    ),
                    Text(
                      userResearch.pointsRecherche.toStringAsFixed(1),
                      style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: hospitalTextColor),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Liste des Recherches Débloquées
                Text(
                  'Protocoles Actifs :',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: hospitalTextColor),
                ),
                const SizedBox(height: 8),
                if (userResearch.recherchesDebloquees.isEmpty)
                  Text(
                    'Aucun protocole actif pour l\'instant.',
                    style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic),
                  )
                else
                  ...userResearch.recherchesDebloquees.map((rechercheId) {
                    final researchOption = availableResearchOptions.firstWhere(
                          (opt) => opt.id == rechercheId,
                      orElse: () => ResearchOption(id: rechercheId, name: 'Protocole Inconnu', description: '', cost: 0),
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user_outlined, size: 18, color: hospitalPrimaryGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              researchOption.name,
                              style: GoogleFonts.roboto(fontSize: 16, color: hospitalTextColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Tuile pour chaque option de recherche disponible
  Widget _buildResearchOptionTile(
      BuildContext context,
      WidgetRef ref,
      LaboratoireRecherche userResearch,
      ResearchOption research,
      bool isUnlocked,
      bool canAfford,
      ) {
    Color tileColor = hospitalCardColor;
    double tileElevation = 2.0;
    Color textColorForTile = hospitalTextColor;

    if (isUnlocked) {
      tileColor = hospitalPrimaryGreen.withOpacity(0.1);
      tileElevation = 1.0;
      textColorForTile = hospitalPrimaryGreen;
    } else if (canAfford) {
      tileElevation = 4.0;
    } else {
      tileColor = hospitalBackgroundColor;
      textColorForTile = hospitalSubTextColor;
    }

    return Card(
      color: tileColor,
      elevation: tileElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de la recherche
            Text(
              research.name,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textColorForTile,
              ),
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              research.description,
              style: GoogleFonts.roboto(fontSize: 15, color: hospitalSubTextColor),
            ),
            const SizedBox(height: 12),
            // Coût
            Row(
              children: [
                Icon(Icons.monetization_on_outlined, size: 20, color: hospitalWarningColor),
                const SizedBox(width: 8),
                Text(
                  'Coût : ${research.cost.toStringAsFixed(1)} Points d\'Analyse',
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    color: canAfford ? hospitalPrimaryGreen : hospitalErrorColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Bouton Débloquer
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isUnlocked
                    ? hospitalSubTextColor.withOpacity(0.1)
                    : (canAfford ? hospitalPrimaryGreen
                    : hospitalBackgroundColor),
                foregroundColor: isUnlocked
                    ? hospitalSubTextColor
                    : (canAfford ? Colors.white
                    : hospitalSubTextColor),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: isUnlocked ? BorderSide.none : (canAfford ? BorderSide.none : BorderSide(color: hospitalSubTextColor.withOpacity(0.3), width: 1.0))
                ),
                elevation: isUnlocked ? 0 : (canAfford ? 4.0 : 0),
              ),
              onPressed: isUnlocked ? null : (canAfford ? () {
                print('Tentative de débloquer : ${research.name}');
                _unlockResearch(context, ref, userResearch, research);
              } : null),

              child: Text(
                isUnlocked ? 'Protocole Actif'
                    : (canAfford ? 'Démarrer Analyse'
                    : 'Points Insuffisants'),
                style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}