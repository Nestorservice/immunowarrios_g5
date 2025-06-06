// lib/screens/combat_visualization_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Pour Timestamp

import '../models/agent_pathogene.dart';
import '../models/base_virale.dart';
import '../models/combat_result.dart' as app_combat_result;
import '../services/combat_service.dart';
import '../services/firestore_service.dart';
import '../state/auth_state_provider.dart';
import '../models/laboratoire_recherche.dart'; // Importe le modèle LaboratoireRecherche
import 'combat_history_page.dart'; // Pour l'historique de combat


// Nouvelle Palette de couleurs thématique "Immuno-Médical" (réutilise celle du dashboard)
const Color hospitalPrimaryGreen = Color(0xFF4CAF50);
const Color hospitalAccentPink = Color(0xFFE91E63);
const Color hospitalBackgroundColor = Color(0xFFF5F5F5);
const Color hospitalCardColor = Color(0xFFFFFFFF);
const Color hospitalTextColor = Color(0xFF212121);
const Color hospitalSubTextColor = Color(0xFF757575);
const Color hospitalWarningColor = Color(0xFFFF9800);
const Color hospitalErrorColor = Color(0xFFF44336);
const Color hospitalSuccessColor = hospitalPrimaryGreen;

// Structure pour l'état du combat à chaque étape
class CombatStep {
  final List<AgentPathogene> playerTeamState;
  final List<AgentPathogene> enemyTeamState;
  final String? lastActionDescription; // Description de l'action du tour
  final String? winner; // 'player', 'enemy', 'draw', ou null si combat en cours

  CombatStep({
    required this.playerTeamState,
    required this.enemyTeamState,
    this.lastActionDescription,
    this.winner,
  });
}

class CombatVisualizationPage extends ConsumerStatefulWidget {
  final BaseVirale playerBase;
  final BaseVirale enemyBase;

  const CombatVisualizationPage({
    super.key,
    required this.playerBase,
    required this.enemyBase,
  });

  @override
  ConsumerState<CombatVisualizationPage> createState() => _CombatVisualizationPageState();
}

class _CombatVisualizationPageState extends ConsumerState<CombatVisualizationPage> with SingleTickerProviderStateMixin {
  late List<AgentPathogene> _playerTeam;
  late List<AgentPathogene> _enemyTeam;
  String _currentLog = "Prêt pour le combat...";
  String? _combatWinner; // 'player', 'enemy', 'draw'
  bool _combatEnded = false;
  List<String> _fullCombatLog = []; // Pour stocker le log complet du combat
  final CombatService _combatService = CombatService(); // Instancie le service de combat

  @override
  void initState() {
    super.initState();
    // Crée des copies profondes des pathogènes pour éviter de modifier les objets passés en paramètre
    // et s'assurer que les barres de vie reflètent les PV actuels du combat.
    _playerTeam = widget.playerBase.pathogenes.map((p) => AgentPathogene.fromMap(p.toJson())!).toList();
    _enemyTeam = widget.enemyBase.pathogenes.map((p) => AgentPathogene.fromMap(p.toJson())!).toList();
  }


  Future<void> _startCombat() async {
    setState(() {
      _combatEnded = false;
      _combatWinner = null;
      _fullCombatLog = [];
      _currentLog = "Début de la simulation...";
      // Réinitialise les PV pour un nouveau combat si nécessaire
      _playerTeam = widget.playerBase.pathogenes.map((p) => AgentPathogene.fromMap(p.toJson())!).toList();
      _enemyTeam = widget.enemyBase.pathogenes.map((p) => AgentPathogene.fromMap(p.toJson())!).toList();
    });

    // Utilisation du Stream pour recevoir les mises à jour tour par tour
    _combatService.simulateCombatAsStream(
      playerBase: BaseVirale(id: widget.playerBase.id, nom: widget.playerBase.nom, createurId: widget.playerBase.createurId, pathogenes: _playerTeam),
      enemyBase: BaseVirale(id: widget.enemyBase.id, nom: widget.enemyBase.nom, createurId: widget.enemyBase.createurId, pathogenes: _enemyTeam),
    ).listen((CombatStep step) {
      if (!mounted) return; // S'assurer que le widget est toujours monté

      setState(() {
        _playerTeam = step.playerTeamState;
        _enemyTeam = step.enemyTeamState;
        if (step.lastActionDescription != null) {
          _currentLog = step.lastActionDescription!;
          _fullCombatLog.add(step.lastActionDescription!);
        }
        _combatWinner = step.winner;
        _combatEnded = (step.winner != null); // Le combat est terminé si un vainqueur est désigné
      });

      // Si le combat est terminé, sauvegarde les résultats
      if (_combatEnded) {
        _saveCombatResult(step);
      }
    });
  }

  Future<void> _saveCombatResult(CombatStep finalStep) async {
    final currentUser = ref.read(authStateChangesProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour sauvegarder les résultats du combat.')),
      );
      return;
    }

    final firestoreService = ref.read(firestoreServiceProvider);

    final newCombatResult = app_combat_result.CombatResult(
      id: const Uuid().v4(),
      attackerId: currentUser.uid,
      defenderId: widget.enemyBase.id,
      defenderBaseName: widget.enemyBase.nom,
      combatDate: Timestamp.now(),
      attackerWon: finalStep.winner == 'player',
      playerPathogensRemaining: finalStep.playerTeamState.where((p) => p.pv > 0).length,
      enemyPathogensRemaining: finalStep.enemyTeamState.where((p) => p.pv > 0).length,
      combatLog: _fullCombatLog, // Sauvegarde le log complet
      winner: finalStep.winner ?? 'draw', // S'assurer qu'il y a un vainqueur
    );

    try {
      await firestoreService.saveCombatResult(combatResult: newCombatResult);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newCombatResult.attackerWon
                ? 'Combat terminé : Victoire ! Résultat sauvegardé.'
                : newCombatResult.winner == 'draw'
                ? 'Combat terminé : Égalité ! Résultat sauvegardé.'
                : 'Combat terminé : Défaite... Résultat sauvegardé.',
          ),
          backgroundColor: newCombatResult.attackerWon ? hospitalSuccessColor : hospitalErrorColor,
        ),
      );
      print('Combat result saved to Firestore: ${newCombatResult.id}');

      // Attribution des points de recherche si victoire
      if (newCombatResult.attackerWon) {
        const double baseResearchPoints = 25.0;
        final double gainedResearchPoints = baseResearchPoints;

        // Utilisation de getUserResearch du firestoreService
        final userResearch = await firestoreService.getUserResearch(currentUser.uid);
        // S'assurer que userResearch n'est pas null. S'il l'est, on initialise un nouveau LaboratoireRecherche.
        LaboratoireRecherche currentResearch = userResearch ?? LaboratoireRecherche();


        final double updatedTotalPoints = currentResearch.pointsRecherche + gainedResearchPoints;
        final updatedResearchMap = currentResearch.copyWith(pointsRecherche: updatedTotalPoints).toJson();

        await firestoreService.updateUserProfile(currentUser.uid, {'research': updatedResearchMap});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vous avez gagné ${gainedResearchPoints.toStringAsFixed(1)} points d\'Analyse !'), backgroundColor: hospitalSuccessColor),
        );
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde du combat : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde du combat : ${e.toString()}'), backgroundColor: hospitalErrorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Simulation de Combat',
          style: GoogleFonts.poppins(
            color: hospitalTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: hospitalBackgroundColor,
        elevation: 1.0,
        centerTitle: true,
      ),
      body: SingleChildScrollView( // Rendre la page scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Affichage des équipes
            SizedBox( // Utilise un SizedBox avec une hauteur contrainte si les équipes sont toujours affichées
              height: MediaQuery.of(context).size.height * 0.4, // 40% de la hauteur de l'écran
              child: Row(
                children: [
                  Expanded(child: _buildTeamDisplay(widget.playerBase.nom, _playerTeam, true)), // Votre équipe
                  const SizedBox(width: 20),
                  Expanded(child: _buildTeamDisplay(widget.enemyBase.nom, _enemyTeam, false)), // Équipe ennemie
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Zone de log actuelle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hospitalCardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: hospitalSubTextColor.withOpacity(0.3)),
              ),
              child: Text(
                _currentLog,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(fontSize: 16, color: hospitalTextColor),
              ),
            ),
            const SizedBox(height: 20),
            // Boutons d'action
            _combatEnded
                ? Column(
              children: [
                Text(
                  _combatWinner == 'player'
                      ? 'VICTOIRE !'
                      : _combatWinner == 'enemy'
                      ? 'DÉFAITE !'
                      : 'ÉGALITÉ !',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _combatWinner == 'player'
                        ? hospitalPrimaryGreen
                        : _combatWinner == 'enemy'
                        ? hospitalErrorColor
                        : hospitalWarningColor,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Retourne au dashboard
                        },
                        icon: const Icon(Icons.dashboard),
                        label: const Text('Tableau de bord'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hospitalPrimaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Redirige vers la page d'historique de combat
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const CombatHistoryPage()));
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('Historique'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hospitalAccentPink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
                : ElevatedButton.icon(
              onPressed: _startCombat,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Lancer la Simulation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: hospitalPrimaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                textStyle: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamDisplay(String teamName, List<AgentPathogene> team, bool isPlayerTeam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          teamName,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isPlayerTeam ? hospitalPrimaryGreen : hospitalAccentPink,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Expanded( // <-- Assure que le ListView.builder prend l'espace restant
          child: ListView.builder(
            itemCount: team.length,
            itemBuilder: (context, index) {
              final pathogen = team[index];
              return _buildPathogenCard(pathogen, isPlayerTeam);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPathogenCard(AgentPathogene pathogen, bool isPlayer) {
    // Determine icon and color based on pathogen type
    IconData icon;
    Color iconColor;
    switch (pathogen.type) {
      case 'Virus':
        icon = Icons.coronavirus;
        iconColor = Colors.purple; // Virus icon
        break;
      case 'Bacterie':
        icon = Icons.science; // Bactérie icon
        iconColor = Colors.brown;
        break;
      case 'Champignon': // Assurez-vous d'avoir un modèle Champignon si vous l'utilisez
        icon = Icons.scatter_plot; // Champignon icon
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.bug_report; // Default icon
        iconColor = Colors.grey;
    }

    final double healthPercentage = pathogen.maxPv > 0 ? (pathogen.pv / pathogen.maxPv) : 0.0;
    final Color healthColor = healthPercentage > 0.5
        ? hospitalPrimaryGreen // Vert si bonne santé
        : healthPercentage > 0.2
        ? hospitalWarningColor // Orange si santé moyenne
        : hospitalErrorColor; // Rouge si santé critique

    return Card(
      color: hospitalCardColor,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: iconColor),
                const SizedBox(width: 8),
                Flexible( // Utiliser Flexible pour le texte du nom
                  child: Text(
                    pathogen.type, // Affiche le type plutôt qu'un nom générique
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: hospitalTextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Barre de vie
            LinearProgressIndicator(
              value: healthPercentage,
              backgroundColor: hospitalSubTextColor.withOpacity(0.3),
              color: healthColor,
              minHeight: 8,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 5),
            Text(
              'PV: ${pathogen.pv.toStringAsFixed(1)} / ${pathogen.maxPv.toStringAsFixed(1)}',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: hospitalSubTextColor,
              ),
            ),
            const SizedBox(height: 10),
            // Infos additionnelles si besoin
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // CORRECTION ICI : Envelopper chaque _buildStatChip avec Expanded
                Expanded(child: _buildStatChip(Icons.flash_on, 'Att: ${pathogen.degats.toStringAsFixed(0)}', Colors.red)),
                Expanded(child: _buildStatChip(Icons.shield, 'Arm: ${pathogen.armure.toStringAsFixed(0)}', Colors.blue)),
                Expanded(child: _buildStatChip(Icons.speed, 'Init: ${pathogen.initiative}', Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(label, style: GoogleFonts.roboto(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}