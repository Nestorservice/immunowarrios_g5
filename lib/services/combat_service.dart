import '../models/base_virale.dart';
import '../models/agent_pathogene.dart'; // Assure-toi d'importer les modèles nécessaires
import 'dart:math'; // Nécessaire pour la sélection aléatoire

// Une classe simple pour stocker le résultat d'un combat
class CombatResult {
  final String winner; // 'player', 'enemy', ou 'draw' (si égalité ou limite de tours)
  final int playerPathogensRemaining;
  final int enemyPathogensRemaining;
  final List<String> combatLog; // Une liste de chaînes de caractères décrivant le déroulement

  CombatResult({
    required this.winner,
    required this.playerPathogensRemaining,
    required this.enemyPathogensRemaining,
    required this.combatLog,
  });
}


// Service pour la simulation de combat
class CombatService {

  // Méthode pour simuler un combat
  CombatResult simulateCombat({
    required BaseVirale playerBase,
    required BaseVirale enemyBase,
    int maxRounds = 100, // Limite le nombre de tours pour éviter les boucles infinies
  }) {
    final combatLog = <String>[];
    final random = Random(); // Générateur de nombres aléatoires

    // Créer des copies modifiables des listes de pathogènes (car ils vont subir des dégâts/être éliminés)
    // Il est crucial de travailler sur des COPIES pour ne pas modifier les objets BaseVirale originaux
    final List<AgentPathogene> playerTeam = List.from(playerBase.pathogenes);
    final List<AgentPathogene> enemyTeam = List.from(enemyBase.pathogenes);

    combatLog.add('--- Début du Combat ---');
    combatLog.add('Votre Base : ${playerBase.nom} (${playerTeam.length} pathogènes)');
    combatLog.add('Base Ennemie : ${enemyBase.nom} (${enemyTeam.length} pathogènes)');


    for (int round = 1; round <= maxRounds; round++) {
      combatLog.add('\n--- Tour $round ---');

      // Combiner toutes les unités des deux équipes et les trier par initiative (décroissant)
      final allUnits = [...playerTeam, ...enemyTeam];
      allUnits.sort((a, b) => b.initiative.compareTo(a.initiative)); // Tri par initiative

      for (final unit in allUnits) {
        // Vérifier si l'unité est toujours en vie
        if (unit.pv > 0) {
          // Déterminer l'équipe de l'unité et l'équipe adverse
          final bool isPlayerUnit = playerBase.pathogenes.any((p) => p.id == unit.id); // Utilise any pour vérifier l'ID dans la liste originale (si les copies ont le même ID)
          // Correction: il est plus simple de vérifier si l'unité est dans la liste playerTeam ou enemyTeam (copiées)
          final bool isUnitInPlayerTeam = playerTeam.any((p) => p.id == unit.id);

          List<AgentPathogene> attackingTeam = isUnitInPlayerTeam ? playerTeam : enemyTeam;
          List<AgentPathogene> defendingTeam = isUnitInPlayerTeam ? enemyTeam : playerTeam;

          // Filtrer les unités vivantes de l'équipe adverse
          final livingDefendingTeam = defendingTeam.where((p) => p.pv > 0).toList();

          // Si l'équipe adverse a encore des unités vivantes, l'unité attaque
          if (livingDefendingTeam.isNotEmpty) {
            // Choisir une cible aléatoire parmi les unités vivantes de l'équipe adverse
            final targetIndex = random.nextInt(livingDefendingTeam.length);
            final target = livingDefendingTeam[targetIndex];

            // Calculer les dégâts
            // Dégâts de base après armure : max(0, dégâts_attaquant - armure_cible)
            final baseDamageAfterArmor = max(0.0, unit.degats - target.armure);

            // Calculer le multiplicateur de faiblesse/résistance
            final double weaknessMultiplier = target.faiblesses[unit.typeAttaque] ?? 1.0; // Utilise 1.0 si le type d'attaque n'est pas dans les faiblesses

            // Dégâts finaux
            final finalDamage = baseDamageAfterArmor * weaknessMultiplier;

            // Appliquer les dégâts à la cible (modifier directement l'objet dans la liste copié)
            target.pv -= finalDamage;

            // Ajouter au log
            final attackerTeamName = isUnitInPlayerTeam ? 'Votre' : 'Ennemie';
            final targetTeamName = isUnitInPlayerTeam ? 'Ennemie' : 'Votre';
            final targetPathogenType = target.type; // Assumant que AgentPathogene a une propriété 'type'
            final unitPathogenType = unit.type; // Assumant que AgentPathogene a une propriété 'type'


            combatLog.add('${attackerTeamName} ${unitPathogenType} attaque ${targetTeamName} ${targetPathogenType} pour ${finalDamage.toStringAsFixed(1)} dégâts.');

            // Vérifier si la cible a été éliminée
            if (target.pv <= 0) {
              combatLog.add('${targetTeamName} ${targetPathogenType} a été éliminé !');
            }
          }
        }
      }

      // Vérifier les conditions de victoire/défaite après chaque tour
      final playerTeamAlive = playerTeam.where((p) => p.pv > 0).toList();
      final enemyTeamAlive = enemyTeam.where((p) => p.pv > 0).toList();

      if (playerTeamAlive.isEmpty && enemyTeamAlive.isEmpty) {
        combatLog.add('\n--- Résultat : Égalité (toutes les unités ont été éliminées) ---');
        return CombatResult(winner: 'draw', playerPathogensRemaining: playerTeamAlive.length, enemyPathogensRemaining: enemyTeamAlive.length, combatLog: combatLog);
      } else if (enemyTeamAlive.isEmpty) {
        combatLog.add('\n--- Résultat : Victoire ! Votre équipe a survécu. ---');
        return CombatResult(winner: 'player', playerPathogensRemaining: playerTeamAlive.length, enemyPathogensRemaining: enemyTeamAlive.length, combatLog: combatLog);
      } else if (playerTeamAlive.isEmpty) {
        combatLog.add('\n--- Résultat : Défaite. Votre équipe a été éliminée. ---');
        return CombatResult(winner: 'enemy', playerPathogensRemaining: playerTeamAlive.length, enemyPathogensRemaining: enemyTeamAlive.length, combatLog: combatLog);
      }
    }

    // Si la limite de tours est atteinte sans vainqueur
    combatLog.add('\n--- Résultat : Égalité (Limite de tours atteinte) ---');
    return CombatResult(winner: 'draw', playerPathogensRemaining: playerTeam.where((p) => p.pv > 0).length, enemyPathogensRemaining: enemyTeam.where((p) => p.pv > 0).length, combatLog: combatLog);
  }

}