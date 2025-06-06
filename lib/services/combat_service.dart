// lib/services/combat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // Pour utiliser StreamController
import 'dart:math';

import '../models/base_virale.dart';
import '../models/agent_pathogene.dart';
import '../models/combat_result.dart'; // <<< IMPORTANT : On importe la classe CombatResult unique !
import '../screens/combat_visualization_page.dart'; // Importe la classe CombatStep

class CombatService {

  // Méthode pour simuler un combat et retourner un Stream de CombatStep
  Stream<CombatStep> simulateCombatAsStream({
    required BaseVirale playerBase,
    required BaseVirale enemyBase,
    int maxRounds = 100, // Limite le nombre de tours pour éviter les boucles infinies
  }) async* { // Utilisation de `async*` pour les générateurs de flux (Streams)
    final combatLog = <String>[];
    final random = Random();

    // Créer des copies PROFONDES des pathogènes pour que leurs PV puissent être modifiés
    // sans affecter les objets originaux dans les bases de données ou le dashboard.
    // Il est crucial d'utiliser `fromJson` et `toJson` pour une copie indépendante.
    final List<AgentPathogene> playerTeam = playerBase.pathogenes.map((p) => AgentPathogene.fromMap(p.toJson())!).toList();
    final List<AgentPathogene> enemyTeam = enemyBase.pathogenes.map((p) => AgentPathogene.fromMap(p.toJson())!).toList();


    combatLog.add('--- Début du Combat ---');
    combatLog.add('Votre Base : ${playerBase.nom} (${playerTeam.length} pathogènes)');
    combatLog.add('Base Ennemie : ${enemyBase.nom} (${enemyTeam.length} pathogènes)');

    // Émettre l'état initial
    yield CombatStep(
      playerTeamState: playerTeam.map((p) => AgentPathogene.fromMap(p.toJson())!).toList(), // Copie pour l'état
      enemyTeamState: enemyTeam.map((p) => AgentPathogene.fromMap(p.toJson())!).toList(), // Copie pour l'état
      lastActionDescription: 'Le combat est sur le point de commencer !',
    );
    await Future.delayed(const Duration(seconds: 1)); // Petite pause pour la visibilité

    for (int round = 1; round <= maxRounds; round++) {
      if (playerTeam.where((p) => p.pv > 0).isEmpty || enemyTeam.where((p) => p.pv > 0).isEmpty) {
        break; // Arrête si une équipe est déjà éliminée avant ce tour
      }

      final roundLog = <String>[];
      roundLog.add('--- Tour $round ---');

      // Combiner toutes les unités des deux équipes et les trier par initiative (décroissant)
      // Ne prendre que les unités vivantes pour ce tour
      final allUnits = [...playerTeam.where((p) => p.pv > 0), ...enemyTeam.where((p) => p.pv > 0)];
      allUnits.sort((a, b) => b.initiative.compareTo(a.initiative)); // Tri par initiative

      for (final unit in allUnits) {
        // Vérifier si l'unité est toujours en vie après d'éventuelles attaques précédentes dans le même tour
        if (unit.pv > 0) {
          final bool isUnitInPlayerTeam = playerTeam.any((p) => p.id == unit.id);

          List<AgentPathogene> defendingTeam = isUnitInPlayerTeam ? enemyTeam : playerTeam;

          // Filtrer les unités vivantes de l'équipe adverse pour la cible
          final livingDefendingTeam = defendingTeam.where((p) => p.pv > 0).toList();

          if (livingDefendingTeam.isNotEmpty) {
            final targetIndex = random.nextInt(livingDefendingTeam.length);
            final target = livingDefendingTeam[targetIndex];

            final baseDamageAfterArmor = max(0.0, unit.degats - target.armure);
            final double weaknessMultiplier = target.faiblesses[unit.typeAttaque] ?? 1.0;
            final finalDamage = baseDamageAfterArmor * weaknessMultiplier;

            // Appliquer les dégâts
            target.pv -= finalDamage;

            final attackerTeamName = isUnitInPlayerTeam ? 'Votre' : 'Ennemie';
            final targetTeamName = isUnitInPlayerTeam ? 'Ennemie' : 'Votre';
            final targetPathogenType = target.type;
            final unitPathogenType = unit.type;

            String actionDesc = '${attackerTeamName} ${unitPathogenType} attaque ${targetTeamName} ${targetPathogenType} pour ${finalDamage.toStringAsFixed(1)} dégâts.';
            roundLog.add(actionDesc);

            if (target.pv <= 0) {
              roundLog.add('${targetTeamName} ${targetPathogenType} a été éliminé !');
            }

            // Émettre l'état après chaque action pour une mise à jour dynamique
            yield CombatStep(
              playerTeamState: playerTeam.map((p) => AgentPathogene.fromMap(p.toJson())!).toList(), // Copie de l'état actuel
              enemyTeamState: enemyTeam.map((p) => AgentPathogene.fromMap(p.toJson())!).toList(), // Copie de l'état actuel
              lastActionDescription: roundLog.last, // N'envoie que la dernière action pour l'affichage en cours
            );
            await Future.delayed(const Duration(milliseconds: 700)); // Petite pause
          }
        }
      }

      // Vérifier les conditions de victoire/défaite après chaque tour complet
      final playerTeamAlive = playerTeam.where((p) => p.pv > 0).toList();
      final enemyTeamAlive = enemyTeam.where((p) => p.pv > 0).toList();

      String? winner;
      if (playerTeamAlive.isEmpty && enemyTeamAlive.isEmpty) {
        winner = 'draw';
      } else if (enemyTeamAlive.isEmpty) {
        winner = 'player';
      } else if (playerTeamAlive.isEmpty) {
        winner = 'enemy';
      }

      if (winner != null) {
        yield CombatStep(
          playerTeamState: playerTeamAlive.map((p) => AgentPathogene.fromMap(p.toJson())!).toList(),
          enemyTeamState: enemyTeamAlive.map((p) => AgentPathogene.fromMap(p.toJson())!).toList(),
          lastActionDescription: winner == 'player' ? 'Victoire !' : (winner == 'enemy' ? 'Défaite...' : 'Égalité.'),
          winner: winner,
        );
        return; // Arrête le stream car le combat est fini
      }
      combatLog.addAll(roundLog); // Ajoute le log du tour au log complet
    }

    // Si la limite de tours est atteinte sans vainqueur clair
    yield CombatStep(
      playerTeamState: playerTeam.where((p) => p.pv > 0).map((p) => AgentPathogene.fromMap(p.toJson())!).toList(),
      enemyTeamState: enemyTeam.where((p) => p.pv > 0).map((p) => AgentPathogene.fromMap(p.toJson())!).toList(),
      lastActionDescription: 'Limite de tours atteinte. Match nul !',
      winner: 'draw',
    );
  }
}