// lib/models/combat_result.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // Pour générer un ID unique

class CombatResult {
  final String id; // ID unique pour ce résultat de combat
  final String attackerId; // L'ID du joueur attaquant
  final String defenderId; // L'ID de la base défendue
  final String defenderBaseName; // Le nom de la base défendue
  final Timestamp combatDate; // Date et heure du combat
  final bool attackerWon; // true si l'attaquant (le joueur) a gagné
  final int playerPathogensRemaining; // Nombre de pathogènes restants du joueur
  final int enemyPathogensRemaining; // Nombre de pathogènes restants de l'ennemi
  final List<String> combatLog; // Une liste de chaînes de caractères décrivant le déroulement
  final String winner; // 'player', 'enemy', ou 'draw' (ajouté pour cohérence avec CombatService)


  CombatResult({
    String? id, // Optionnel à la création, généré si null
    required this.attackerId,
    required this.defenderId,
    required this.defenderBaseName,
    required this.combatDate,
    required this.attackerWon,
    required this.playerPathogensRemaining,
    required this.enemyPathogensRemaining,
    required this.combatLog,
    required this.winner, // Ajouté ici
  }) : id = id ?? const Uuid().v4(); // Génère un ID si non fourni

  // Factory constructor pour créer une instance de CombatResult à partir d'une Map (Firestore)
  factory CombatResult.fromJson(Map<String, dynamic> json) {
    return CombatResult(
      id: json['id'] as String,
      attackerId: json['attackerId'] as String,
      defenderId: json['defenderId'] as String,
      defenderBaseName: json['defenderBaseName'] as String,
      combatDate: json['combatDate'] as Timestamp,
      attackerWon: json['attackerWon'] as bool,
      playerPathogensRemaining: json['playerPathogensRemaining'] as int,
      enemyPathogensRemaining: json['enemyPathogensRemaining'] as int,
      combatLog: List<String>.from(json['combatLog'] as List<dynamic>),
      winner: json['winner'] as String, // Ajouté ici
    );
  }

  // Méthode pour convertir une instance de CombatResult en Map (pour Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attackerId': attackerId,
      'defenderId': defenderId,
      'defenderBaseName': defenderBaseName,
      'combatDate': combatDate,
      'attackerWon': attackerWon,
      'playerPathogensRemaining': playerPathogensRemaining,
      'enemyPathogensRemaining': enemyPathogensRemaining,
      'combatLog': combatLog,
      'winner': winner, // Ajouté ici
    };
  }
}