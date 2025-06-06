// lib/screens/combat_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importe Timestamp

// Importe les providers nécessaires
import '../state/auth_state_provider.dart';
import '../models/base_virale.dart';
import '../services/combat_service.dart';
import '../services/firestore_service.dart'; // <<< NOUVEL IMPORT : Pour sauvegarder dans Firestore
import '../models/combat_result.dart'; // <<< NOUVEL IMPORT : Ton modèle CombatResult

// baseDetailsProvider.family est défini dans base_details_page.dart, donc on l'importe pour l'utiliser.
import 'base_details_page.dart';
import 'combat_visualization_page.dart'; // Pour importer CombatStep

// --- Palette de couleurs thématique "Immuno-Médical" ---
const Color hospitalPrimaryGreen = Color(0xFF4CAF50);
const Color hospitalAccentPink = Color(0xFFE91E63);
const Color hospitalBackgroundColor = Color(0xFFF5F5F5);
const Color hospitalCardColor = Color(0xFFFFFFFF);
const Color hospitalTextColor = Color(0xFF212121);
const Color hospitalSubTextColor = Color(0xFF757570);
const Color hospitalWarningColor = Color(0xFFFF9800);
const Color hospitalErrorColor = Color(0xFFF44336);

// --- Redéfinition locale de playerBaseProvider si non accessible depuis un import ---
// Idéalement, ce provider devrait être défini dans auth_state_provider.dart ou un fichier dédié aux providers.
// Si l'import 'bio_forge_page.dart' pour playerBaseProvider ne fonctionne pas ou si vous voulez
// que ce provider soit disponible globalement pour toutes les pages qui en ont besoin,
// déplacez cette définition vers auth_state_provider.dart et assurez-vous d'importer firestoreServiceProvider là-bas.
// Pour l'instant, je vais le redéfinir ici temporairement si l'import échoue.
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
// --- Fin de la redéfinition locale ---


class CombatPage extends ConsumerStatefulWidget {
  final String enemyBaseId;

  const CombatPage({super.key, required this.enemyBaseId});

  @override
  _CombatPageState createState() => _CombatPageState();
}

class _CombatPageState extends ConsumerState<CombatPage> {
  // Ici, on stocke le résultat de la simulation dans une variable locale
  // pour l'afficher sur la page après le combat.
  CombatResult? _simulationDisplayResult; // Renommé pour éviter la confusion avec le modèle

  // Méthode pour lancer la simulation de combat ET sauvegarder le résultat.
  void _runSimulation({
    required BaseVirale playerBase,
    required BaseVirale enemyBase,
  }) async {
    final combatService = CombatService();
    final firestoreService = ref.read(firestoreServiceProvider);
    final currentUser = ref.read(authStateChangesProvider).value;

    if (currentUser == null) {
      print('Erreur: Aucun utilisateur connecté pour lancer le combat.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour simuler un combat.')),
      );
      return;
    }

    print('Lancement de la simulation...');
    List<String> combatLog = [];
    CombatStep? finalStep;

    // S'abonne au stream de CombatStep pour récupérer le log complet et le résultat final
    await for (var step in combatService.simulateCombatAsStream(
      playerBase: playerBase,
      enemyBase: enemyBase,
    )) {
      if (step.lastActionDescription != null) {
        combatLog.add(step.lastActionDescription!);
      }
      if (step.winner != null) {
        finalStep = step; // Capture la dernière étape qui contient le vainqueur
        break; // Le combat est terminé, on peut sortir de la boucle
      }
    }

    if (finalStep == null) {
      // Cela ne devrait normalement pas arriver si simulateCombatAsStream garantit un vainqueur ou une fin
      print('Erreur: La simulation n\'a pas retourné de résultat final.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la simulation du combat.')),
      );
      return;
    }

    // 2. Créer un objet CombatResult COMPLET pour l'enregistrement Firestore
    final combatResultToSave = CombatResult(
      attackerId: currentUser.uid,
      defenderId: enemyBase.id,
      defenderBaseName: enemyBase.nom,
      combatDate: Timestamp.now(), // Date actuelle du combat
      attackerWon: finalStep.winner == 'player', // true si le joueur a gagné
      playerPathogensRemaining: finalStep.playerTeamState.where((p) => p.pv > 0).length,
      enemyPathogensRemaining: finalStep.enemyTeamState.where((p) => p.pv > 0).length,
      combatLog: combatLog, // Utilise le log accumulé
      winner: finalStep.winner!, // Le gagnant tel que retourné par le simulateur
    );

    // 3. Sauvegarder le résultat dans Firestore
    try {
      await firestoreService.saveCombatResult(combatResult: combatResultToSave);
      print('Résultat du combat sauvegardé avec succès dans Firestore !');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Combat simulé et enregistré !')),
      );
    } catch (e) {
      print('Erreur lors de la sauvegarde du résultat du combat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde du combat: $e')),
      );
    }

    // Met à jour l'état et reconstruit le widget pour afficher le résultat
    setState(() {
      _simulationDisplayResult = combatResultToSave; // Affiche le CombatResult complet
    });

    print('\n--- Log Complet du Combat ---');
    for (var logEntry in combatLog) {
      print(logEntry);
    }
    print('---------------------------\n');
  }


  @override
  Widget build(BuildContext context) {
    final playerBaseAsyncValue = ref.watch(playerBaseProvider);
    final enemyBaseAsyncValue = ref.watch(baseDetailsProvider(widget.enemyBaseId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Simulation de Conflit', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: hospitalPrimaryGreen,
        elevation: 1.0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: hospitalBackgroundColor,
      body: playerBaseAsyncValue.when(
        loading: () => Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: hospitalPrimaryGreen),
            const SizedBox(height: 16),
            Text('Préparation de votre équipe pour l\'analyse...', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic)),
          ],
        )),
        error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('Erreur lors de la préparation de votre équipe : ${err.toString()}', textAlign: TextAlign.center, style: GoogleFonts.roboto(color: hospitalErrorColor, fontSize: 16)),
            )),
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

          return enemyBaseAsyncValue.when(
            loading: () => Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: hospitalAccentPink),
                const SizedBox(height: 16),
                Text('Analyse de l\'échantillon ennemi...', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic)),
              ],
            )),
            error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('Erreur lors de l\'analyse de l\'échantillon ennemi : ${err.toString()}', textAlign: TextAlign.center, style: GoogleFonts.roboto(color: hospitalErrorColor, fontSize: 16)),
                )),
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

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Tests de Stress Immunitaire', textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.bold, color: hospitalAccentPink)),
                    const SizedBox(height: 30),

                    _buildBaseInfoPanel(
                      title: 'Votre Équipe Immunitaire',
                      icon: Icons.shield_outlined,
                      iconColor: hospitalPrimaryGreen,
                      base: playerBase,
                    ),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        children: [
                          const Expanded(child: Divider(color: hospitalSubTextColor, thickness: 0.5)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(' VS ', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: hospitalSubTextColor)),
                          ),
                          const Expanded(child: Divider(color: hospitalSubTextColor, thickness: 0.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildBaseInfoPanel(
                      title: 'Échantillon Pathogène Ennemi',
                      icon: Icons.bug_report_outlined,
                      iconColor: hospitalAccentPink,
                      base: enemyBase,
                    ),

                    const SizedBox(height: 30),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _simulationDisplayResult == null ? hospitalAccentPink : hospitalSubTextColor.withOpacity(0.3),
                        foregroundColor: _simulationDisplayResult == null ? Colors.white : hospitalSubTextColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        elevation: _simulationDisplayResult == null ? 4.0 : 0,
                      ),
                      onPressed: _simulationDisplayResult == null ? () {
                        print('Lancement de la simulation...');
                        _runSimulation(playerBase: playerBase, enemyBase: enemyBase);
                      } : null,
                      icon: Icon(_simulationDisplayResult == null ? Icons.play_arrow_outlined : Icons.check_circle_outline),
                      label: Text(_simulationDisplayResult == null ? 'Démarrer l\'Analyse' : 'Analyse Terminée', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),

                    const SizedBox(height: 30),

                    if (_simulationDisplayResult != null)
                      _buildSimulationResultPanel(_simulationDisplayResult!),

                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBaseInfoPanel({required String title, required IconData icon, required Color iconColor, required BaseVirale base}) {
    return Card(
      color: hospitalCardColor,
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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

  Widget _buildSimulationResultPanel(CombatResult result) {
    Color winnerColor = hospitalTextColor;
    if (result.winner == 'player') {
      winnerColor = hospitalPrimaryGreen;
    } else if (result.winner == 'enemy') {
      winnerColor = hospitalErrorColor;
    } else if (result.winner == 'draw') {
      winnerColor = hospitalWarningColor;
    }


    return Card(
      color: hospitalCardColor,
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rapport d\'Analyse', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: hospitalTextColor)),
            const Divider(color: hospitalSubTextColor, height: 20, thickness: 0.5),
            Text('Issue de la Simulation : ${result.winner}', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: winnerColor)),
            const SizedBox(height: 8),
            Text('Votre Équipe Restante : ${result.playerPathogensRemaining} contaminants', style: GoogleFonts.roboto(fontSize: 15, color: hospitalTextColor)),
            Text('Échantillon Ennemi Restant : ${result.enemyPathogensRemaining} contaminants', style: GoogleFonts.roboto(fontSize: 15, color: hospitalTextColor)),
            const SizedBox(height: 20),
            Text('Détails de l\'Analyse :', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: hospitalTextColor)),
            const SizedBox(height: 8),
            ...result.combatLog.map((logEntry) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    logEntry,
                    style: GoogleFonts.roboto(fontSize: 13, color: hospitalSubTextColor),
                  ),
                )
            ).toList(),
          ],
        ),
      ),
    );
  }
}