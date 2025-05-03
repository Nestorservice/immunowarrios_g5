// Indique que c'est une classe abstraite
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
  // (On ne les définit pas ici, juste leur "signature")
  // On ajoutera des méthodes plus tard pour les capacités spéciales
  // Par exemple :
  // void capaciteSpeciale();

  // Une méthode pour appliquer des dégâts (sera utilisée en combat)
  void subirDegats(double degatsSubis, String typeAttaque);

  // Une méthode pour simuler une attaque (sera utilisée en combat)
  // Elle prendrait une cible en paramètre, mais on garde simple pour l'instant
  void attaquer();

  // Méthode pour convertir un objet AgentPathogene en Map (pour le stocker dans Firestore/Hive)
  // Une méthode abstraite de sérialisation est utile ici
  Map<String, dynamic> toJson();
}

// On va implémenter les méthodes concrètes subirDegats et attaquer
// dans les classes enfants car elles pourraient varier légèrement par type
// (par exemple, l'armure pourrait interagir différemment, ou l'attaque pourrait avoir des effets spécifiques)