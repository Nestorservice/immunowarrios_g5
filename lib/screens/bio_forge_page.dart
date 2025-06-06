// lib/screens/bio_forge_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // Nécessaire pour générer des ID uniques
import 'package:google_fonts/google_fonts.dart'; // Importe Google Fonts

import '../models/base_virale.dart';
// Importe les modèles spécifiques dont on aura besoin
import '../models/ressources_defensives.dart';
import '../models/laboratoire_recherche.dart';
import '../models/memoire_immunitaire.dart';
import '../models/agent_pathogene.dart'; // Assure-toi que ce modèle existe
// Importe les classes spécifiques des pathogènes si tu les utilises directement
import '../models/virus.dart'; // Exemple : si tu ajoutes des Virus
import '../models/bacterie.dart'; // Exemple : si tu ajoutes des Bactéries
// import '../models/champignon.dart'; // Exemple : si tu utilises Champignons

import '../state/auth_state_provider.dart'; // Importe tous nos providers
// Importe FirestoreService
import '../services/firestore_service.dart';


// Un Provider qui regarde la base virale *du joueur actuellement connecté*.
// Il dépend de authStateChangesProvider (pour l'UID) et utilise streamViralBase.
// Renvoie un Stream<BaseVirale?>.
final userViralBaseProvider = StreamProvider.autoDispose<BaseVirale?>((ref) { // Renommé de playerBaseProvider pour éviter la confusion avec le passé
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user != null) {
        final userId = user.uid;
        final firestoreService = ref.watch(firestoreServiceProvider);
        return firestoreService.streamViralBase(userId);
      }
      return Stream.value(null);
    },
    loading: () => Stream.value(null),
    error: (err, stack) => Stream.value(null),
  );
});

// --- Palette de couleurs thématique "Immuno-Médical" ---
// Réutilise les couleurs
const Color hospitalPrimaryGreen = Color(0xFF4CAF50); // Vert Médical
const Color hospitalAccentPink = Color(0xFFE91E63); // Rose Vif
const Color hospitalBackgroundColor = Color(0xFFF5F5F5); // Fond clair
const Color hospitalCardColor = Color(0xFFFFFFFF); // Fond blanc carte
const Color hospitalTextColor = Color(0xFF212121); // Texte sombre
const Color hospitalSubTextColor = Color(0xFF757575); // Texte gris
const Color hospitalWarningColor = Color(0xFFFF9800); // Orange
const Color hospitalErrorColor = Color(0xFFF44336); // Rouge
const Color hospitalSuccessColor = hospitalPrimaryGreen; // Pour les messages de succès


class BioForgePage extends ConsumerStatefulWidget {
  const BioForgePage({super.key});

  @override
  ConsumerState<BioForgePage> createState() => _BioForgePageState();
}

class _BioForgePageState extends ConsumerState<BioForgePage> {
  final Uuid _uuid = const Uuid(); // Instance de Uuid pour générer des IDs

  // Fonction pour retirer un pathogène avec messages SnackBar stylisés
  void _removePathogen(BuildContext context, WidgetRef ref, BaseVirale currentBase, String pathogenIdToRemove) async {
    final currentUser = ref.read(authStateChangesProvider).value;
    if (currentUser == null) {
      if (!mounted) return; // Vérifie si le widget est toujours monté
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Connectez-vous pour modifier votre base.'), backgroundColor: hospitalErrorColor),
      );
      return;
    }
    final userId = currentUser.uid;

    final updatedPathogensList = currentBase.pathogenes
        .where((pathogene) => pathogene.id != pathogenIdToRemove)
        .toList();

    final updatedBase = currentBase.copyWith(pathogenes: updatedPathogensList); // Utilise copyWith pour une meilleure pratique

    final firestoreService = ref.read(firestoreServiceProvider);

    try {
      await firestoreService.savePlayerBase(userId: userId, base: updatedBase);
      print('Pathogène $pathogenIdToRemove retiré et base sauvegardée.');
      if (!mounted) return; // Vérifie si le widget est toujours monté
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Pathogène retiré de votre base.'), backgroundColor: hospitalWarningColor), // Utilise warning pour retrait (attention)
      );
    } catch (e) {
      print('Erreur lors du retrait du pathogène ou de la sauvegarde : $e');
      if (!mounted) return; // Vérifie si le widget est toujours monté
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du retrait : ${e.toString()}'), backgroundColor: hospitalErrorColor), // Rouge erreur
      );
    }
  }

  // Fonction pour ajouter un nouveau pathogène (Virus ou Bactérie) à la base virale
  Future<void> _addPathogen(BuildContext context, WidgetRef ref, BaseVirale currentBase, String pathogenType) async {
    final currentUser = ref.read(authStateChangesProvider).value;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Connectez-vous pour forger des pathogènes.'), backgroundColor: hospitalErrorColor),
      );
      return;
    }
    final userId = currentUser.uid;

    final firestoreService = ref.read(firestoreServiceProvider);

    try {
      // Pas besoin de récupérer la base ici, elle est passée par currentBase.
      // Créer un nouveau pathogène basé sur le type choisi
      final newPathogenId = _uuid.v4();
      AgentPathogene newPathogen; // Type spécifique pour AgentPathogene

      if (pathogenType == 'Virus') {
        newPathogen = Virus(
          id: newPathogenId,
          pv: 100.0,
          maxPv: 100.0,
          armure: 10.0,
          typeAttaque: 'corrosive',
          degats: 25.0,
          initiative: 5,
          faiblesses: {'physique': 1.5, 'energetique': 0.7},
        );
      } else if (pathogenType == 'Bacterie') {
        newPathogen = Bacterie(
          id: newPathogenId,
          pv: 120.0,
          maxPv: 120.0,
          armure: 15.0,
          typeAttaque: 'infectieuse',
          degats: 20.0,
          initiative: 4,
          faiblesses: {'feu': 1.5, 'froid': 0.7},
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Type de pathogène inconnu.'), backgroundColor: hospitalErrorColor),
        );
        return;
      }

      // Ajouter le nouveau pathogène à la liste existante
      final updatedPathogensList = List<AgentPathogene>.from(currentBase.pathogenes)..add(newPathogen);

      // Utilise copyWith pour créer une nouvelle instance de BaseVirale
      final updatedBase = currentBase.copyWith(pathogenes: updatedPathogensList);

      // Sauvegarder la base virale mise à jour dans Firestore
      await firestoreService.savePlayerBase(userId: userId, base: updatedBase);
      print('Nouveau pathogène $newPathogenId ($pathogenType) ajouté.');

      if (!mounted) return; // Vérifie si le widget est toujours monté
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$pathogenType synthétisé avec succès !'), backgroundColor: hospitalSuccessColor),
      );
    } catch (e) {
      print('Erreur lors de l\'ajout du pathogène ou de la sauvegarde : $e');
      if (!mounted) return; // Vérifie si le widget est toujours monté
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la synthèse du pathogène : ${e.toString()}'), backgroundColor: hospitalErrorColor),
      );
    }
  }

  // Fonction pour afficher la boîte de dialogue de sélection du type de pathogène
  void _showPathogenTypeSelectionDialog(BuildContext context, WidgetRef ref, BaseVirale currentBase) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: hospitalCardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Choisir le Type de Pathogène',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: hospitalTextColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.sick_outlined, color: hospitalPrimaryGreen),
                title: Text('Virus', style: GoogleFonts.roboto(color: hospitalTextColor)),
                onTap: () {
                  Navigator.of(dialogContext).pop(); // Ferme la boîte de dialogue
                  _addPathogen(context, ref, currentBase, 'Virus'); // Passe 'Virus' comme type
                },
              ),
              ListTile(
                leading: Icon(Icons.science_outlined, color: hospitalAccentPink),
                title: Text('Bactérie', style: GoogleFonts.roboto(color: hospitalTextColor)),
                onTap: () {
                  Navigator.of(dialogContext).pop(); // Ferme la boîte de dialogue
                  _addPathogen(context, ref, currentBase, 'Bacterie'); // Passe 'Bactérie' comme type
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Annuler',
                style: GoogleFonts.roboto(color: hospitalSubTextColor),
              ),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final userProfileAsyncValue = ref.watch(userProfileProvider);
    final playerBaseAsyncValue = ref.watch(userViralBaseProvider); // Utilise le Provider renommé

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Unité de Bio-Synthèse',
          style: GoogleFonts.poppins(color: hospitalTextColor, fontWeight: FontWeight.bold), // Utilise hospitalTextColor
        ),
        backgroundColor: hospitalBackgroundColor, // Utilise hospitalBackgroundColor
        elevation: 1.0,
        centerTitle: true,
        // iconTheme: const IconThemeData(color: Colors.white), // Plus besoin si AppBar est clair
      ),
      backgroundColor: hospitalBackgroundColor,
      body: userProfileAsyncValue.when(
        data: (profileData) {
          if (profileData == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off_outlined, size: 60, color: hospitalSubTextColor),
                    const SizedBox(height: 16),
                    Text(
                      'Profil utilisateur non disponible.\nVeuillez vous connecter pour accéder à la Bio-Forge.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(fontSize: 18, color: hospitalSubTextColor),
                    ),
                  ],
                ),
              ),
            );
          }

          final RessourcesDefensives? userResources = ref.watch(userResourcesProvider);
          final LaboratoireRecherche? userResearch = ref.watch(userResearchProvider);
          final MemoireImmunitaire? userImmuneMemory = ref.watch(userImmuneMemoryProvider);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Laboratoire de Culturisme Pathogène',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: hospitalAccentPink,
                  ),
                ),
                const SizedBox(height: 30),

                _buildInfoPanel(
                  title: 'Réserves Biologiques',
                  icon: Icons.inventory_2_outlined,
                  iconColor: hospitalPrimaryGreen,
                  content: userResources != null
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.bolt, 'Énergie Cellulaire', userResources.energie.toStringAsFixed(1), hospitalAccentPink),
                      _buildInfoRow(Icons.science_outlined, 'Bio-matériaux Synthétiques', userResources.bioMateriaux.toStringAsFixed(1), hospitalPrimaryGreen),
                    ],
                  )
                      : Center(child: Text('Ressources non disponibles.', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic))),
                ),
                const SizedBox(height: 20),

                _buildInfoPanel(
                  title: 'Connaissances Virales',
                  icon: Icons.menu_book_outlined,
                  iconColor: hospitalWarningColor,
                  content: userResearch != null
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.analytics_outlined, 'Points d\'Analyse', userResearch.pointsRecherche.toStringAsFixed(1), hospitalAccentPink),
                      const SizedBox(height: 10),
                      Text(
                        'Protocoles Débloqués :',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: hospitalTextColor),
                      ),
                      const SizedBox(height: 4),
                      if (userResearch.recherchesDebloquees.isEmpty)
                        Text(
                          'Aucun protocole actif.',
                          style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic),
                        )
                      else
                        ...userResearch.recherchesDebloquees.map((id) =>
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline, size: 16, color: hospitalPrimaryGreen),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(id, style: GoogleFonts.roboto(fontSize: 15, color: hospitalTextColor), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            )
                        ).toList(),
                    ],
                  )
                      : Center(child: Text('Données R&D non disponibles.', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic))),
                ),
                const SizedBox(height: 20),

                _buildInfoPanel(
                  title: 'Banque de Données Immunitaire',
                  icon: Icons.local_hospital_outlined,
                  iconColor: hospitalPrimaryGreen,
                  content: userImmuneMemory != null
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.bug_report_outlined, 'Types Connus', userImmuneMemory.typesConnus.join(', '), hospitalAccentPink),
                      const SizedBox(height: 10),
                      Text(
                        'Bonus d\'Efficacité :',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: hospitalTextColor),
                      ),
                      const SizedBox(height: 4),
                      if (userImmuneMemory.bonusEfficacite.isEmpty)
                        Text(
                          'Aucun bonus actif.',
                          style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic),
                        )
                      else
                        ...userImmuneMemory.bonusEfficacite.entries.map((e) =>
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                children: [
                                  Icon(Icons.star_rate_outlined, size: 16, color: hospitalWarningColor),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text('${e.key}: ${e.value.toStringAsFixed(1)}', style: GoogleFonts.roboto(fontSize: 15, color: hospitalTextColor), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            )
                        ).toList(),
                    ],
                  )
                      : Center(child: Text('Mémoire Immunitaire non disponible.', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic))),
                ),
                const SizedBox(height: 20),


                _buildInfoPanel(
                  title: 'Collecte Pathogène',
                  icon: Icons.folder_special_outlined,
                  iconColor: hospitalAccentPink,
                  content: playerBaseAsyncValue.when(
                    data: (BaseVirale? playerBase) { // playerBase peut être null
                      if (playerBase == null) {
                        return Center(child: Text('Aucune base personnelle détectée. Créez-en une !', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic)));
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nom de la Base : ${playerBase.nom ?? 'Base sans nom'}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: hospitalTextColor)),
                          const SizedBox(height: 8),
                          const Divider(color: hospitalSubTextColor, height: 15, thickness: 0.3),
                          Text('Pathogènes en culture :', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: hospitalTextColor)),
                          const SizedBox(height: 8),

                          if (playerBase.pathogenes.isEmpty)
                            Center(child: Text('Votre base ne contient aucun pathogène.', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic)))
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: playerBase.pathogenes.length,
                              itemBuilder: (context, index) {
                                final pathogene = playerBase.pathogenes[index];
                                return _buildPathogenTile(context, ref, playerBase, pathogene);
                              },
                            ),

                          const SizedBox(height: 20),

                          Center(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hospitalPrimaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                elevation: 3.0,
                              ),
                              // Appelle la boîte de dialogue de sélection du type de pathogène
                              onPressed: playerBase != null // Active le bouton seulement si la base existe
                                  ? () => _showPathogenTypeSelectionDialog(context, ref, playerBase)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                              label: Text('Synthétiser Pathogène', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          )

                        ],
                      );
                    },
                    loading: () => Center(child: CircularProgressIndicator(color: hospitalAccentPink)),
                    error: (err, stack) => Center(child: Text('Erreur de chargement de votre base : ${err.toString()}', style: GoogleFonts.roboto(color: hospitalErrorColor))),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: hospitalPrimaryGreen, key: const ValueKey('profileLoading'))),
        error: (err, stack) => Center(child: Text('Erreur de chargement du profil : ${err.toString()}', style: GoogleFonts.roboto(color: hospitalErrorColor))),
      ),
    );
  }

  // Widget générique pour les panneaux d'information
  Widget _buildInfoPanel({required String title, required IconData icon, required Color iconColor, required Widget content}) {
    return Card(
      color: hospitalCardColor,
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: hospitalTextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(color: hospitalSubTextColor, height: 25, thickness: 0.5),
            content,
          ],
        ),
      ),
    );
  }

  // Widget helper pour une ligne d'information dans un panneau
  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              '$label :',
              style: GoogleFonts.roboto(fontSize: 16, color: hospitalSubTextColor),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: hospitalTextColor),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour une tuile individuelle de pathogène dans la liste
  Widget _buildPathogenTile(BuildContext context, WidgetRef ref, BaseVirale currentBase, AgentPathogene pathogene) {
    return Card(
      color: hospitalBackgroundColor,
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Icône du pathogène (peut-être basée sur le type plus tard)
            Icon(Icons.bug_report_outlined, size: 28, color: hospitalAccentPink.withOpacity(0.8)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type et PV
                  Text(
                    '${pathogene.type} - PV: ${pathogene.pv.toStringAsFixed(1)} / ${pathogene.maxPv.toStringAsFixed(1)}',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: hospitalTextColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Armure et Dégâts (exemple d'autres stats)
                  Text(
                    'Armure: ${pathogene.armure.toStringAsFixed(1)} - Dégâts: ${pathogene.degats.toStringAsFixed(1)}',
                    style: GoogleFonts.roboto(fontSize: 14, color: hospitalSubTextColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Bouton Retirer
            IconButton(
              icon: const Icon(Icons.delete_outline, color: hospitalErrorColor),
              tooltip: 'Retirer ce pathogène',
              onPressed: () {
                print('Tentative de retrait du pathogène ${pathogene.id}');
                _removePathogen(context, ref, currentBase, pathogene.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}