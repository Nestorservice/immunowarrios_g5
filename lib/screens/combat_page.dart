import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart'; // Importe Google Fonts

// Importe les providers nécessaires
import '../state/auth_state_provider.dart'; // userProfileProvider (dont dépend playerBaseProvider)
import '../models/base_virale.dart'; // Importe le modèle BaseVirale
// baseDetailsProvider.family est défini dans base_details_page.dart, donc on l'importe pour l'utiliser.
import 'base_details_page.dart'; // Nécessaire pour baseDetailsProvider
// Importe le service de combat que tu viens de créer
import '../services/combat_service.dart';
// Importe playerBaseProvider depuis bio_forge_page (si défini là-bas) ou un fichier partagé
// Assurez-vous que playerBaseProvider est bien accessible, soit en l'important
// depuis un fichier commun, soit en le redéfinissant si c'est la structure de votre projet.
// Pour cet exemple, je vais supposer qu'il est défini dans un fichier partagé ou bio_forge_page
// et que l'import ci-dessous fonctionne si playerBaseProvider est public.
// Si playerBaseProvider n'est pas public dans bio_forge_page.dart, vous devriez le définir dans auth_state_provider.dart ou un fichier partagé.
// Pour l'instant, je vais le redéfinir ici temporairement si l'import échoue.

// --- Palette de couleurs thématique "Immuno-Médical" ---
// Réutilise les couleurs
const Color hospitalPrimaryGreen = Color(0xFF4CAF50); // Vert Médical
const Color hospitalAccentPink = Color(0xFFE91E63); // Rose Vif
const Color hospitalBackgroundColor = Color(0xFFF5F5F5); // Fond clair
const Color hospitalCardColor = Color(0xFFFFFFFF); // Fond blanc carte
const Color hospitalTextColor = Color(0xFF212121); // Texte sombre
const Color hospitalSubTextColor = Color(0xFF757570); // Texte gris
const Color hospitalWarningColor = Color(0xFFFF9800); // Orange
const Color hospitalErrorColor = Color(0xFFF44336); // Rouge

// --- Redéfinition locale de playerBaseProvider si non accessible depuis un import ---
// Idéalement, ce provider devrait être défini dans auth_state_provider.dart ou un fichier dédié aux providers.
// Si l'import 'bio_forge_page.dart' pour playerBaseProvider ne fonctionne pas ou si vous voulez
// que ce provider soit disponible globalement pour toutes les pages qui en ont besoin,
// déplacez cette définition vers auth_state_provider.dart et assurez-vous d'importer firestoreServiceProvider là-bas.
final playerBaseProvider = StreamProvider.autoDispose<BaseVirale?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.when(
    data: (user) {
      if (user != null) {
        final firestoreService = ref.watch(firestoreServiceProvider); // Assurez-vous que firestoreServiceProvider est accessible
        return firestoreService.streamViralBase(user.uid);
      }
      return Stream.value(null);
    },
    loading: () => Stream.value(null),
    error: (err, stack) => Stream.value(null),
  );
});
// --- Fin de la redéfinition locale ---


// Cette page affiche les informations des deux bases pour le combat et gère la simulation.
// On utilise un ConsumerStatefulWidget pour gérer l'état du résultat de la simulation ET utiliser ref.
class CombatPage extends ConsumerStatefulWidget {
  // La page a besoin de l'ID de la base ennemie
  final String enemyBaseId;

  const CombatPage({super.key, required this.enemyBaseId});

  @override
  _CombatPageState createState() => _CombatPageState();
}

// La classe d'état pour la page de combat.
class _CombatPageState extends ConsumerState<CombatPage> {

  CombatResult? _combatResult; // Variable d'état pour le résultat

  // Méthode pour lancer la simulation de combat.
  void _runSimulation({
    required BaseVirale playerBase,
    required BaseVirale enemyBase,
  }) {
    // Crée une instance du service
    final combatService = CombatService();

    // Lance la simulation
    final result = combatService.simulateCombat(
      playerBase: playerBase,
      enemyBase: enemyBase,
    );

    // Met à jour l'état et reconstruit le widget pour afficher le résultat
    setState(() {
      _combatResult = result;
    });

    // Optionnel : imprimer le log complet dans la console pour débogage.
    print('\n--- Log Complet du Combat ---');
    for (var logEntry in result.combatLog) {
      print(logEntry);
    }
    print('---------------------------\n');
  }


  @override
  Widget build(BuildContext context) {
    // Regarde la base du joueur
    final playerBaseAsyncValue = ref.watch(playerBaseProvider);

    // Regarde la base ennemie en utilisant l'ID passé au widget
    final enemyBaseAsyncValue = ref.watch(baseDetailsProvider(widget.enemyBaseId));


    // On utilise des .when() imbriqués pour gérer l'état des deux AsyncValue
    return Scaffold(
      // AppBar stylisée
      appBar: AppBar(
        title: Text('Simulation de Conflit', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), // Titre adapté, police propre
        backgroundColor: hospitalPrimaryGreen, // Fond vert
        elevation: 1.0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // Icônes blanches
      ),
      backgroundColor: hospitalBackgroundColor, // Fond clair
      body: playerBaseAsyncValue.when(
        // Chargement base joueur
        loading: () => Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: hospitalPrimaryGreen),
            const SizedBox(height: 16),
            Text('Préparation de votre équipe pour l\'analyse...', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic)),
          ],
        )),
        // Erreur base joueur
        error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('Erreur lors de la préparation de votre équipe : ${err.toString()}', textAlign: TextAlign.center, style: GoogleFonts.roboto(color: hospitalErrorColor, fontSize: 16)),
            )),
        // Base joueur chargée
        data: (playerBase) {
          if (playerBase == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_off_outlined, size: 60, color: hospitalSubTextColor),
                    const SizedBox(height: 16),
                    Text(
                      'Votre équipe immunitaire n\'est pas disponible.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(fontSize: 18, color: hospitalSubTextColor),
                    ),
                  ],
                ),
              ),
            );
          }

          // Gère l'état de la base ennemie
          return enemyBaseAsyncValue.when(
            // Chargement base ennemie
            loading: () => Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: hospitalAccentPink),
                const SizedBox(height: 16),
                Text('Analyse de l\'échantillon ennemi...', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic)),
              ],
            )),
            // Erreur base ennemie
            error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('Erreur lors de l\'analyse de l\'échantillon ennemi : ${err.toString()}', textAlign: TextAlign.center, style: GoogleFonts.roboto(color: hospitalErrorColor, fontSize: 16)),
                )),
            // Base ennemie chargée
            data: (enemyBase) {
              if (enemyBase == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.find_in_page_outlined, size: 60, color: hospitalSubTextColor),
                        const SizedBox(height: 16),
                        Text(
                          'Échantillon ennemi introuvable pour l\'analyse.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(fontSize: 18, color: hospitalSubTextColor),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Si les deux bases sont chargées
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0), // Padding général
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Titre principal
                    Text('Tests de Stress Immunitaire', textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.bold, color: hospitalAccentPink)), // Titre adapté, rose vif
                    const SizedBox(height: 30),

                    // --- Panneau Votre Équipe ---
                    _buildBaseInfoPanel(
                      title: 'Votre Équipe Immunitaire', // Titre adapté
                      icon: Icons.shield_outlined, // Icône bouclier/défense
                      iconColor: hospitalPrimaryGreen, // Vert
                      base: playerBase,
                    ),
                    const SizedBox(height: 20),

                    // --- Séparateur vs ---
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        children: [
                          const Expanded(child: Divider(color: hospitalSubTextColor, thickness: 0.5)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(' VS ', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: hospitalSubTextColor)), // Texte VS stylisé
                          ),
                          const Expanded(child: Divider(color: hospitalSubTextColor, thickness: 0.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),


                    // --- Panneau Équipe Ennemie ---
                    _buildBaseInfoPanel(
                      title: 'Échantillon Pathogène Ennemi', // Titre adapté
                      icon: Icons.bug_report_outlined, // Icône bug/pathogène
                      iconColor: hospitalAccentPink, // Rose vif
                      base: enemyBase,
                    ),

                    const SizedBox(height: 30),

                    // **BOUTON POUR LANCER LA SIMULATION :**
                    ElevatedButton.icon( // Bouton avec icône
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _combatResult == null ? hospitalAccentPink : hospitalSubTextColor.withOpacity(0.3), // Rose vif si activable, gris si terminé
                        foregroundColor: _combatResult == null ? Colors.white : hospitalSubTextColor, // Texte blanc si activable, gris si terminé
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        elevation: _combatResult == null ? 4.0 : 0, // Ombre si activable
                      ),
                      onPressed: _combatResult == null ? () {
                        print('Lancement de la simulation...');
                        _runSimulation(playerBase: playerBase, enemyBase: enemyBase);
                      } : null,
                      icon: Icon(_combatResult == null ? Icons.play_arrow_outlined : Icons.check_circle_outline), // Icône play ou check
                      label: Text(_combatResult == null ? 'Démarrer l\'Analyse' : 'Analyse Terminée', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold)), // Texte adapté
                    ),

                    const SizedBox(height: 30),

                    // **AFFICHAGE DU RÉSULTAT DE LA SIMULATION :**
                    if (_combatResult != null)
                      _buildSimulationResultPanel(_combatResult!), // Widget helper pour le résultat

                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Widgets helper pour le design (adaptés au thème hospitalier) ---

  // Widget pour afficher les informations d'une base (joueur ou ennemie)
  Widget _buildBaseInfoPanel({required String title, required IconData icon, required Color iconColor, required BaseVirale base}) {
    return Card(
      color: hospitalCardColor, // Fond blanc
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: iconColor), // Icône du panneau
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title, // Titre (Votre Équipe / Échantillon Ennemi)
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: hospitalTextColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(color: hospitalSubTextColor, height: 20, thickness: 0.5),

            Text('Nom : ${base.nom ?? 'Base sans nom'}', style: GoogleFonts.roboto(fontSize: 16, color: hospitalTextColor)),
            const SizedBox(height: 8),
            Text('Pathogènes en présence : ${base.pathogenes.length}', style: GoogleFonts.roboto(fontSize: 16, color: hospitalTextColor)),
            // TODO: Ajouter ici un résumé des statistiques de la base (total PV, attaque moyenne, etc.)
            // Exemple simple:
            if (base.pathogenes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('PV Totaux Est. : ${base.pathogenes.fold(0.0, (sum, p) => sum + p.pv).toStringAsFixed(1)}', style: GoogleFonts.roboto(fontSize: 14, color: hospitalSubTextColor)),
              ),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher le panneau des résultats de simulation
  Widget _buildSimulationResultPanel(CombatResult result) {
    // Détermine la couleur pour le vainqueur
    Color winnerColor = hospitalTextColor;
    if (result.winner.contains('Joueur')) { // Adapter la chaîne 'Joueur' si elle change
      winnerColor = hospitalPrimaryGreen; // Vert si le joueur gagne
    } else if (result.winner.contains('Ennemi')) { // Adapter la chaîne 'Ennemi' si elle change
      winnerColor = hospitalErrorColor; // Rouge si l'ennemi gagne
    }


    return Card(
      color: hospitalCardColor, // Fond blanc
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rapport d\'Analyse', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: hospitalTextColor)), // Titre adapté
            const Divider(color: hospitalSubTextColor, height: 20, thickness: 0.5),
            Text('Issue de la Simulation : ${result.winner}', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: winnerColor)), // Vainqueur stylisé
            const SizedBox(height: 8),
            Text('Votre Équipe Restante : ${result.playerPathogensRemaining} contaminants', style: GoogleFonts.roboto(fontSize: 15, color: hospitalTextColor)), // Texte stylisé
            Text('Échantillon Ennemi Restant : ${result.enemyPathogensRemaining} contaminants', style: GoogleFonts.roboto(fontSize: 15, color: hospitalTextColor)), // Texte stylisé
            const SizedBox(height: 20),
            Text('Détails de l\'Analyse :', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: hospitalTextColor)), // Titre log adapté
            const SizedBox(height: 8),
            // Affiche le log de combat avec un style pour chaque ligne
            ...result.combatLog.map((logEntry) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    logEntry,
                    style: GoogleFonts.roboto(fontSize: 13, color: hospitalSubTextColor), // Police plus petite et grise pour le log
                  ),
                )
            ).toList(),
          ],
        ),
      ),
    );
  }

} // Fin de la classe CombatPage