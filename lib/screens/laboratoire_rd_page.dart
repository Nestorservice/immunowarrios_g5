import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importe Google Fonts
import 'package:google_fonts/google_fonts.dart';

import '../state/auth_state_provider.dart';
// Assure-toi que ce modèle est importé et que LaboratoireRecherche y est défini
import '../models/laboratoire_recherche.dart'; // <-- IMPORTANT
// Importe FirestoreService
import '../services/firestore_service.dart';


// Définition simple d'une recherche (inchangé)
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

// Liste de toutes les recherches disponibles dans le jeu (inchangé)
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

// --- Palette de couleurs thématique "Immuno-Médical" (clair, propre) ---
// Réutilise les couleurs définies pour le tableau de bord
const Color hospitalPrimaryGreen = Color(0xFF4CAF50); // Vert Médical (Principal, Thème)
const Color hospitalAccentPink = Color(0xFFE91E63); // Rose Vif (Accent, Attention)
const Color hospitalBackgroundColor = Color(0xFFF5F5F5); // Fond clair principal (Gris très clair)
const Color hospitalCardColor = Color(0xFFFFFFFF); // Fond blanc pour les panneaux / cartes (Propre)
const Color hospitalTextColor = Color(0xFF212121); // Texte sombre sur fond clair (Lecture facile)
const Color hospitalSubTextColor = Color(0xFF757575); // Texte moins important / labels (Gris moyen)
const Color hospitalWarningColor = Color(0xFFFF9800); // Orange (Avertissement, R&D)
const Color hospitalErrorColor = Color(0xFFF44336); // Rouge Vif (Erreur, Déconnexion)
// Pour la cohérence, utilisons la même couleur pour le succès que le vert primaire ou un vert distinct si vous préférez.
// Conservons le vert primaire pour les actions/messages de succès.
const Color hospitalSuccessColor = hospitalPrimaryGreen; // Vert pour les messages de succès


class LaboratoireRDPage extends ConsumerWidget {
  const LaboratoireRDPage({super.key});

  // Fonction pour débloquer une recherche (utilise les couleurs de la nouvelle palette)
  void _unlockResearch(BuildContext context, WidgetRef ref, LaboratoireRecherche currentResearch, ResearchOption researchToUnlock) async {
    final currentUser = ref.read(authStateChangesProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Connectez-vous pour débloquer des recherches.'), backgroundColor: hospitalErrorColor), // Rouge erreur
      );
      return;
    }
    final userId = currentUser.uid;

    if (currentResearch.recherchesDebloquees.contains(researchToUnlock.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Cette recherche est déjà débloquée.'), backgroundColor: hospitalWarningColor), // Orange avertissement
      );
      return;
    }

    if (currentResearch.pointsRecherche < researchToUnlock.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Points de recherche insuffisants. Coût : ${researchToUnlock.cost.toStringAsFixed(1)}.'), backgroundColor: hospitalWarningColor), // Orange avertissement
      );
      return;
    }

    final double updatedPoints = currentResearch.pointsRecherche - researchToUnlock.cost;
    final List<String> updatedResearchesDebloquees = List.from(currentResearch.recherchesDebloquees)..add(researchToUnlock.id);

    final updatedResearchMap = LaboratoireRecherche(
      pointsRecherche: updatedPoints,
      recherchesDebloquees: updatedResearchesDebloquees,
    ).toJson();

    // Assurez-vous que firestoreServiceProvider est accessible via ref
    final firestoreService = ref.read(firestoreServiceProvider);

    try {
      await firestoreService.updateUserProfile(userId, {'research': updatedResearchMap});
      print('Recherche "${researchToUnlock.name}" débloquée pour $userId.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recherche "${researchToUnlock.name}" débloquée !'), backgroundColor: hospitalSuccessColor), // Vert succès
      );
    } catch (e) {
      print('Erreur lors du déblocage de la recherche ou de la sauvegarde : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du déblocage de la recherche : ${e.toString()}'), backgroundColor: hospitalErrorColor), // Rouge erreur
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // userResearch est lu ici, dépendant de userProfileProvider dans le hook useDocument
    final LaboratoireRecherche? userResearch = ref.watch(userResearchProvider);
    // On continue de regarder userProfileProvider pour gérer les états de chargement/erreur globaux
    final userProfileAsyncValue = ref.watch(userProfileProvider);

    return Scaffold(
      // AppBar thématique claire et propre
      appBar: AppBar(
        title: Text(
          'Laboratoire de Recherche', // Titre adapté
          style: GoogleFonts.poppins( // Police propre pour le titre
            color: hospitalTextColor, // Texte sombre
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: hospitalBackgroundColor, // Fond clair de l'AppBar
        elevation: 1.0, // Légère ombre
        centerTitle: true,
      ),
      // Corps avec fond clair
      body: Container(
        color: hospitalBackgroundColor, // Fond très clair pour le corps
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0), // Padding général
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Étirer
            children: [
              // --- Titre de la Page ---
              Text(
                'Centre d\'Analyse Biologique', // Nouveau titre style hospitalier
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat( // Police plus percutante pour le titre principal
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: hospitalPrimaryGreen, // Couleur verte thématique
                ),
              ),
              const SizedBox(height: 30), // Espace

              // --- Panneau de Progression R&D (Statistiques de Recherche) ---
              _buildResearchProgressPanel(userResearch, userProfileAsyncValue),

              const SizedBox(height: 40), // Espace avant les recherches disponibles

              // --- Titre de la section Recherches Disponibles ---
              Text(
                'Protocoles de Recherche Disponibles', // Titre de section
                style: GoogleFonts.poppins( // Police propre
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: hospitalAccentPink, // Rose vif pour cette section (innovation)
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20), // Espace

              // --- Liste des Recherches Disponibles ---
              userProfileAsyncValue.when( // Utilise le when de l'asyncValue global
                data: (profileData) {
                  if (userResearch == null) {
                    // Affiche un indicateur ou un message en attendant les données R&D
                    return Center(child: Column(
                      children: [
                        CircularProgressIndicator(color: hospitalAccentPink),
                        const SizedBox(height: 16),
                        Text('Chargement des protocoles...', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic)),
                      ],
                    ));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: availableResearchOptions.length,
                    itemBuilder: (context, index) {
                      final research = availableResearchOptions[index];
                      final bool isUnlocked = userResearch.recherchesDebloquees.contains(research.id);
                      final bool canAfford = userResearch.pointsRecherche >= research.cost;

                      // Widget helper pour chaque élément de recherche
                      return _buildResearchOptionTile(
                        context,
                        ref,
                        userResearch,
                        research,
                        isUnlocked,
                        canAfford,
                      );
                    },
                  );
                },
                // Gestion des états de chargement/erreur du profil global
                loading: () => Center(child: CircularProgressIndicator(color: hospitalPrimaryGreen)), // Vert pour chargement global
                error: (err, stack) => Center(child: Text('Erreur de chargement : ${err.toString()}', style: TextStyle(color: hospitalErrorColor))), // Rouge erreur globale
              ),

              // TODO: Ajouter d'autres sections du Laboratoire R&D
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets helper pour le design (adaptés au thème hospitalier) ---

  // Panneau de Progression R&D (Statistiques de Recherche)
  Widget _buildResearchProgressPanel(LaboratoireRecherche? userResearch, AsyncValue<Object?> userProfileAsyncValue) {
    return Card(
      color: hospitalCardColor, // Fond blanc propre
      elevation: 2.0, // Légère ombre
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Coins légèrement arrondis
      child: Padding(
        padding: const EdgeInsets.all(20.0), // Padding intérieur
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques de Recherche', // Titre du panneau adapté
              style: GoogleFonts.poppins( // Police et couleur pour le titre
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: hospitalPrimaryGreen, // Vert
              ),
            ),
            const Divider(color: hospitalSubTextColor, height: 25, thickness: 0.5), // Ligne de séparation

            userProfileAsyncValue.when( // Utilise le when ici aussi pour être sûr de l'état
              data: (profileData) {
                if (userResearch == null) {
                  return Center(child: Text('Données de recherche non disponibles.', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic)));
                }
                // Si userResearch est disponible, affiche les détails
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Affichage Points de Recherche
                    Row(
                      children: [
                        Icon(Icons.analytics_outlined, size: 28, color: hospitalAccentPink), // Icône adaptée (analyse/stats)
                        const SizedBox(width: 10),
                        Text(
                          'Points d\'Analyse : ', // Label adapté
                          style: GoogleFonts.roboto(fontSize: 18, color: hospitalSubTextColor), // Police et couleur
                        ),
                        Text(
                          userResearch.pointsRecherche.toStringAsFixed(1), // Valeur
                          style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: hospitalTextColor), // Police et couleur
                        ),
                      ],
                    ),
                    const SizedBox(height: 15), // Espace

                    // Liste des Recherches Débloquées
                    Text(
                      'Protocoles Actifs :', // Titre de la sous-section adapté
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: hospitalTextColor), // Police et couleur
                    ),
                    const SizedBox(height: 8),
                    if (userResearch.recherchesDebloquees.isEmpty)
                      Text(
                        'Aucun protocole actif pour l\'instant.', // Texte adapté
                        style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic), // Police et couleur
                      )
                    else
                    // Liste stylisée des recherches débloquées
                      ...userResearch.recherchesDebloquees.map((rechercheId) {
                        final researchOption = availableResearchOptions.firstWhere(
                              (opt) => opt.id == rechercheId,
                          orElse: () => ResearchOption(id: rechercheId, name: 'Protocole Inconnu', description: '', cost: 0), // Fallback
                        );
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.verified_user_outlined, size: 18, color: hospitalPrimaryGreen), // Icône vérifié/actif
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  researchOption.name, // Nom ou fallback
                                  style: GoogleFonts.roboto(fontSize: 16, color: hospitalTextColor), // Police et couleur
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                );
              },
              // Gestion des états globaux
              loading: () => Center(child: CircularProgressIndicator(color: hospitalPrimaryGreen)), // Vert pour chargement
              error: (err, stack) => Center(child: Text('Erreur de chargement R&D : ${err.toString()}', style: TextStyle(color: hospitalErrorColor))), // Rouge erreur
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
    // Détermine la couleur de fond de la carte et l'élévation selon l'état
    Color tileColor = hospitalCardColor; // Blanc par défaut
    double tileElevation = 2.0; // Légère ombre
    Color textColorForTile = hospitalTextColor; // Texte sombre par défaut
    Color iconColorForTile = hospitalPrimaryGreen; // Vert par défaut pour les icônes de cette section

    if (isUnlocked) {
      tileColor = hospitalPrimaryGreen.withOpacity(0.1); // Vert très pâle si débloqué
      tileElevation = 1.0;
      textColorForTile = hospitalPrimaryGreen; // Texte vert si débloqué
    } else if (canAfford) {
      tileElevation = 4.0; // Plus d'ombre si abordable (met en valeur)
      iconColorForTile = hospitalAccentPink; // Icône rose vif si abordable
    } else {
      tileColor = hospitalBackgroundColor; // Gris très clair si inabordable (grisé)
      textColorForTile = hospitalSubTextColor; // Texte gris si inabordable
      iconColorForTile = hospitalSubTextColor.withOpacity(0.5); // Icône grisée
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
              style: GoogleFonts.poppins( // Police propre
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textColorForTile, // Couleur basée sur l'état
              ),
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              research.description,
              style: GoogleFonts.roboto(fontSize: 15, color: hospitalSubTextColor), // Police standard, gris moyen
            ),
            const SizedBox(height: 12),
            // Coût
            Row(
              children: [
                Icon(Icons.monetization_on_outlined, size: 20, color: hospitalWarningColor), // Icône coût orange
                const SizedBox(width: 8),
                Text(
                  'Coût : ${research.cost.toStringAsFixed(1)} Points d\'Analyse', // Label adapté
                  style: GoogleFonts.roboto( // Police standard
                    fontSize: 15,
                    color: canAfford ? hospitalPrimaryGreen : hospitalErrorColor, // Vert si abordable, rouge sinon
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
                    ? hospitalSubTextColor.withOpacity(0.1) // Très légèrement teinté si débloqué
                    : (canAfford ? hospitalPrimaryGreen // Vert si abordable
                    : hospitalBackgroundColor), // Gris très clair si inabordable
                foregroundColor: isUnlocked
                    ? hospitalSubTextColor // Texte gris si débloqué
                    : (canAfford ? Colors.white // Texte blanc sur bouton vert
                    : hospitalSubTextColor), // Texte gris si inabordable
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: isUnlocked ? BorderSide.none : (canAfford ? BorderSide.none : BorderSide(color: hospitalSubTextColor.withOpacity(0.3), width: 1.0)) // Bordure si inabordable
                ),
                elevation: isUnlocked ? 0 : (canAfford ? 4.0 : 0), // Moins d'ombre si débloqué ou inabordable
              ),
              // Le bouton est actif seulement si PAS débloqué ET peut payer
              onPressed: isUnlocked ? null : (canAfford ? () {
                print('Tentative de débloquer : ${research.name}');
                _unlockResearch(context, ref, userResearch!, research); // Ajouté '!' car on vérifie si userResearch est null avant d'afficher la liste
              } : null), // Désactive si déjà débloqué ou ne peut pas payer

              child: Text(
                isUnlocked ? 'Protocole Actif' // Texte si débloqué
                    : (canAfford ? 'Démarrer Analyse' // Texte si abordable
                    : 'Points Insuffisants'), // Texte si inabordable
                style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold), // Police standard et gras
              ),
            ),
          ],
        ),
      ),
    );
  }
}