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
final playerBaseProvider = StreamProvider.autoDispose<BaseVirale?>((ref) {
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

class BioForgePage extends ConsumerWidget {
  const BioForgePage({super.key});

  // Fonction pour retirer un pathogène avec messages SnackBar stylisés
  void _removePathogen(BuildContext context, WidgetRef ref, BaseVirale currentBase, String pathogenIdToRemove) async {
    final currentUser = ref.read(authStateChangesProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Connectez-vous pour modifier votre base.'), backgroundColor: hospitalErrorColor),
      );
      return;
    }
    final userId = currentUser.uid;

    final updatedPathogensList = currentBase.pathogenes
        .where((pathogene) => pathogene.id != pathogenIdToRemove)
        .toList();

    final updatedBase = BaseVirale(
      id: currentBase.id,
      nom: currentBase.nom,
      createurId: currentBase.createurId,
      pathogenes: updatedPathogensList,
    );

    final firestoreService = ref.read(firestoreServiceProvider);

    try {
      await firestoreService.savePlayerBase(userId: userId, base: updatedBase);
      print('Pathogène $pathogenIdToRemove retiré et base sauvegardée.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Pathogène retiré de votre base.'), backgroundColor: hospitalWarningColor), // Utilise warning pour retrait (attention)
      );
    } catch (e) {
      print('Erreur lors du retrait du pathogène ou de la sauvegarde : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du retrait : ${e.toString()}'), backgroundColor: hospitalErrorColor), // Rouge erreur
      );
    }
  }

  // Fonction pour ajouter un pathogène avec messages SnackBar stylisés
  void _addPathogen(BuildContext context, WidgetRef ref, BaseVirale currentBase) async {
    final currentUser = ref.read(authStateChangesProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Connectez-vous pour ajouter des pathogènes.'), backgroundColor: hospitalErrorColor),
      );
      return;
    }
    final userId = currentUser.uid;

    // **Créer un nouveau pathogène exemple (Virus simple)**
    final newPathogen = Virus(
      id: const Uuid().v4(),
      pv: 40.0, // Légèrement amélioré
      maxPv: 40.0,
      armure: 4.0,
      typeAttaque: 'neurotoxique', // Nouveau type
      degats: 8.0,
      initiative: 10,
      faiblesses: {'énergétique': 1.5, 'physique': 0.7},
    );

    final updatedPathogensList = [...currentBase.pathogenes, newPathogen];

    final updatedBase = BaseVirale(
      id: currentBase.id,
      nom: currentBase.nom,
      createurId: currentBase.createurId,
      pathogenes: updatedPathogensList,
    );

    final firestoreService = ref.read(firestoreServiceProvider);

    try {
      await firestoreService.savePlayerBase(userId: userId, base: updatedBase);
      print('Nouveau pathogène ${newPathogen.id} (${newPathogen.type}) ajouté.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nouveau pathogène "${newPathogen.type}" synthétisé !'), backgroundColor: hospitalPrimaryGreen), // Vert succès
      );
    } catch (e) {
      print('Erreur lors de l\'ajout du pathogène ou de la sauvegarde : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la synthèse : ${e.toString()}'), backgroundColor: hospitalErrorColor), // Rouge erreur
      );
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsyncValue = ref.watch(userProfileProvider);
    final playerBaseAsyncValue = ref.watch(playerBaseProvider);

    return Scaffold(
      // AppBar thématique claire
      appBar: AppBar(
        title: Text('Unité de Bio-Synthèse', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), // Titre adapté, police propre
        backgroundColor: hospitalAccentPink, // Rose vif pour cette page
        elevation: 1.0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // Icônes blanches
      ),
      backgroundColor: hospitalBackgroundColor, // Fond clair
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

          // Accède aux valeurs des providers dérivés si profileData est non-null
          final RessourcesDefensives? userResources = ref.watch(userResourcesProvider);
          final LaboratoireRecherche? userResearch = ref.watch(userResearchProvider);
          final MemoireImmunitaire? userImmuneMemory = ref.watch(userImmuneMemoryProvider);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0), // Padding général
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Étirer les éléments
              children: [
                // --- Titre de la Page ---
                Text(
                  'Laboratoire de Culturisme Pathogène', // Nouveau titre style hospitalier/biologique
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat( // Police percutante
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: hospitalAccentPink, // Rose vif
                  ),
                ),
                const SizedBox(height: 30),

                // --- Panneau des Ressources ---
                _buildInfoPanel( // Widget helper pour les panneaux
                  title: 'Réserves Biologiques',
                  icon: Icons.inventory_2_outlined,
                  iconColor: hospitalPrimaryGreen,
                  content: userResources != null
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.bolt, 'Énergie Cellulaire', userResources.energie.toStringAsFixed(1), hospitalAccentPink), // Rose
                      _buildInfoRow(Icons.science_outlined, 'Bio-matériaux Synthétiques', userResources.bioMateriaux.toStringAsFixed(1), hospitalPrimaryGreen), // Vert
                      // Ajoute d'autres ressources si besoin
                    ],
                  )
                      : Center(child: Text('Ressources non disponibles.', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic))),
                ),
                const SizedBox(height: 20),

                // --- Panneau de la Recherche ---
                _buildInfoPanel(
                  title: 'Connaissances Virales',
                  icon: Icons.menu_book_outlined, // Icône livre/connaissance
                  iconColor: hospitalWarningColor, // Orange
                  content: userResearch != null
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.analytics_outlined, 'Points d\'Analyse', userResearch.pointsRecherche.toStringAsFixed(1), hospitalAccentPink), // Rose
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
                                  Expanded(child: Text(id, style: GoogleFonts.roboto(fontSize: 15, color: hospitalTextColor), overflow: TextOverflow.ellipsis)), // TODO: Afficher le nom complet si possible
                                ],
                              ),
                            )
                        ).toList(),
                    ],
                  )
                      : Center(child: Text('Données R&D non disponibles.', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic))),
                ),
                const SizedBox(height: 20),

                // --- Panneau de la Mémoire Immunitaire ---
                _buildInfoPanel(
                  title: 'Banque de Données Immunitaire',
                  icon: Icons.local_hospital_outlined, // Icône hôpital/santé
                  iconColor: hospitalPrimaryGreen, // Vert
                  content: userImmuneMemory != null
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.bug_report_outlined, 'Types Connus', userImmuneMemory.typesConnus.join(', '), hospitalAccentPink), // Rose
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
                                  Icon(Icons.star_rate_outlined, size: 16, color: hospitalWarningColor), // Icône étoile/bonus
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


                // --- Panneau de Votre Base Virale ---
                _buildInfoPanel(
                  title: 'Collecte Pathogène',
                  icon: Icons.folder_special_outlined, // Icône dossier spécial
                  iconColor: hospitalAccentPink, // Rose vif
                  content: playerBaseAsyncValue.when(
                    data: (playerBase) {
                      if (playerBase == null) {
                        return Center(child: Text('Aucune base personnelle détectée.', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic)));
                        // TODO: Ajouter un bouton stylisé pour créer la base
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nom de la Base : ${playerBase.nom ?? 'Base sans nom'}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: hospitalTextColor)),
                          const SizedBox(height: 8),
                          const Divider(color: hospitalSubTextColor, height: 15, thickness: 0.3), // Séparateur
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
                                // Widget helper pour chaque élément de pathogène
                                return _buildPathogenTile(context, ref, playerBase, pathogene);
                              },
                            ),

                          const SizedBox(height: 20),

                          // Bouton Ajouter un Pathogène (Stylisé)
                          Center( // Centre le bouton
                            child: ElevatedButton.icon( // Bouton avec icône
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hospitalPrimaryGreen, // Fond vert
                                foregroundColor: Colors.white, // Texte blanc
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                elevation: 3.0,
                              ),
                              onPressed: () {
                                print('Tentative d\'ajout d\'un pathogène');
                                // Appelle la fonction pour ajouter le pathogène
                                _addPathogen(context, ref, playerBase); // Passer le contexte
                              },
                              icon: const Icon(Icons.add_circle_outline), // Icône d'ajout
                              label: Text('Synthétiser Pathogène', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold)), // Texte adapté
                            ),
                          )

                        ],
                      );
                    },
                    loading: () => Center(child: CircularProgressIndicator(color: hospitalAccentPink)), // Indicateur rose
                    error: (err, stack) => Center(child: Text('Erreur de chargement de votre base : ${err.toString()}', style: GoogleFonts.roboto(color: hospitalErrorColor))), // Texte erreur rouge
                  ),
                ),


                const SizedBox(height: 20),

                // TODO: Ajouter d'autres sections de la Bio-Forge

              ],
            ),
          );
        },
        // Gère l'état de chargement global du profil
        loading: () => Center(child: CircularProgressIndicator(color: hospitalPrimaryGreen, key: const ValueKey('profileLoading'))), // Indicateur vert
        // Gère l'état d'erreur global du profil
        error: (err, stack) => Center(child: Text('Erreur de chargement du profil : ${err.toString()}', style: GoogleFonts.roboto(color: hospitalErrorColor))), // Texte erreur rouge
      ),
    );
  }

  // --- Widgets helper pour le design (adaptés au thème hospitalier) ---

  // Widget générique pour les panneaux d'information (Ressources, Recherche, Mémoire)
  Widget _buildInfoPanel({required String title, required IconData icon, required Color iconColor, required Widget content}) {
    return Card(
      color: hospitalCardColor, // Fond blanc
      elevation: 2.0, // Légère ombre
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Coins légèrement arrondis
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: iconColor), // Icône du panneau
                const SizedBox(width: 10),
                Expanded( // Permet au texte de prendre l'espace restant
                  child: Text(
                    title, // Titre du panneau
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: hospitalTextColor, // Texte sombre
                    ),
                    overflow: TextOverflow.ellipsis, // Gère le débordement
                  ),
                ),
              ],
            ),
            const Divider(color: hospitalSubTextColor, height: 25, thickness: 0.5), // Ligne de séparation
            content, // Le contenu spécifique du panneau
          ],
        ),
      ),
    );
  }

  // Widget helper pour une ligne d'information dans un panneau (avec icône, label, valeur)
  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor), // Icône de l'item
          const SizedBox(width: 8),
          Expanded( // Permet au label de prendre l'espace
            flex: 2, // Le label prend un peu plus de place
            child: Text(
              '$label :', // Label
              style: GoogleFonts.roboto(fontSize: 16, color: hospitalSubTextColor), // Police standard, gris moyen
            ),
          ),
          Expanded( // Permet à la valeur de prendre l'espace restant
            flex: 3, // La valeur prend le reste
            child: Text(
              value, // Valeur
              style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: hospitalTextColor), // Police pour les valeurs, texte sombre
              textAlign: TextAlign.right, // Aligne la valeur à droite
              overflow: TextOverflow.ellipsis, // Gère le débordement
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour une tuile individuelle de pathogène dans la liste
  Widget _buildPathogenTile(BuildContext context, WidgetRef ref, BaseVirale currentBase, AgentPathogene pathogene) {
    return Card( // Utilise une carte intérieure pour chaque pathogène
      color: hospitalBackgroundColor, // Fond très clair pour la tuile du pathogène
      elevation: 1.0, // Très légère ombre
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), // Petite marge
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Icône du pathogène (peut-être basée sur le type plus tard)
            Icon(Icons.bug_report_outlined, size: 28, color: hospitalAccentPink.withOpacity(0.8)), // Icône bug, couleur rose semi-opaque
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
                  // TODO: Afficher d'autres stats pertinentes
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Bouton Retirer
            IconButton(
              icon: const Icon(Icons.delete_outline, color: hospitalErrorColor), // Icône corbeille, rouge
              tooltip: 'Retirer ce pathogène',
              onPressed: () {
                print('Tentative de retrait du pathogène ${pathogene.id}');
                _removePathogen(context, ref, currentBase, pathogene.id); // Passe le contexte et ref
              },
            ),
          ],
        ),
      ),
    );
  }

} // Fin de la classe BioForgePage