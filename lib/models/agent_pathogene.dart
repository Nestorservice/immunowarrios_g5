// Indique que c'est une classe abstraite
import 'package:immuno_warriors/models/virus.dart';

import 'bacterie.dart';
import 'champignon.dart';

abstract class AgentPathogene {
  // Attributs communs à tous les pathogènes
  final String id; // Un identifiant unique pour chaque instance (utile pour les listes)
  final String type; // Ex: 'virus', 'bacterie', 'champignon'
  double pv; // Points de Vie actuels (on utilise double car ils vont changer)
  final double maxPv; // Points de Vie maximum
  final double armure; // Réduit les dégâts subis
  final String typeAttaque; // Ex: 'corrosive', 'perforante', 'energetique'
  final double degats; // Quantité de dégâts infligés par attaque
  final int initiative; // Détermine l'ordre d'action en combat

  // Attributs pour les faiblesses (une Map pour associer TypeAttaque et multiplicateur)
  // Ex: {'physique': 0.5, 'chimique': 1.5}
  final Map<String, double> faiblesses;

  // Un constructeur pour initialiser les attributs communs
  AgentPathogene({
    required this.id,
    required this.type,
    required this.pv,
    required this.maxPv,
    required this.armure,
    required this.typeAttaque,
    required this.degats,
    required this.initiative,
    this.faiblesses = const {}, // Par défaut, pas de faiblesses spécifiques si non spécifié
  });

  // Méthodes abstraites qui devront être implémentées par les classes enfants
  void subirDegats(double degatsSubis, String typeAttaque);
  void attaquer();

  // Méthode abstraite pour convertir un objet AgentPathogene en Map (pour le stocker dans Firestore/Hive)
  Map<String, dynamic> toJson();


  // **TRÈS IMPORTANT :** CETTE MÉTHODE DOIT ÊTRE ICI, À L'INTÉRIEUR DE LA CLASSE AgentPathogene
  // Elle est static car elle n'agit pas sur une instance spécifique de AgentPathogene,
  // mais sur la classe elle-même pour créer une instance à partir d'une Map.
  static AgentPathogene? fromMap(Map<String, dynamic> map) {
    // Assure-toi que la map contient le champ 'type' pour savoir quel type de pathogène créer
    if (!map.containsKey('type')) {
      print('Erreur de désérialisation : la map ne contient pas le champ "type" pour AgentPathogene.');
      return null; // Impossible de déterminer le type de pathogène
    }

    // En fonction du type, appelle la méthode fromJson appropriée de la classe concrète (Virus, Bacterie, Champignon)
    switch (map['type']) {
      case 'Virus':
      // On importe Virus pour pouvoir appeler Virus.fromJson
      // Assure-toi d'avoir 'import 'virus.dart';' en haut de ce fichier!
        return Virus.fromJson(map);
      case 'Bacterie':
      // On importe Bacterie pour pouvoir appeler Bacterie.fromJson
      // Assure-toi d'avoir 'import 'bacterie.dart';' en haut de ce fichier!
        return Bacterie.fromJson(map);
      case 'Champignon':
      // On importe Champignon pour pouvoir appeler Champignon.fromJson
      // Assure-toi d'avoir 'import 'champignon.dart';' en haut de ce fichier!
        return Champignon.fromJson(map);
      default:
        print('Erreur de désérialisation : type de pathogène inconnu : ${map['type']}');
        return null; // Type inconnu
    }
  }
}

// Assure-toi d'avoir les imports des classes concrètes en haut du fichier AgentPathogene.dart
// import 'virus.dart';
// import 'bacterie.dart';
// import 'champignon.dart';