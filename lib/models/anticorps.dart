// import 'agent_pathogene.dart'; // Peut-être utile plus tard pour les cibles ou interactions

class Anticorps {
  final String id; // Identifiant unique
  final String type; // Ex: 'Spécifique', 'Généraliste' (ou types d'attaque comme 'Physique', 'Chimique')
  double pv; // Points de Vie
  final double maxPv;
  final String typeAttaque; // Doit correspondre aux faiblesses des pathogènes
  final double degats; // Quantité de dégâts
  final int initiative; // Détermine l'ordre d'action
  final double coutRessources; // Coût pour produire cet anticorps
  final int tempsProduction; // Temps nécessaire en "tours" ou secondes
  // Ajoute ici d'autres attributs comme Capacités Spéciales, etc.

  Anticorps({
    required this.id,
    required this.type,
    required this.pv,
    required this.maxPv,
    required this.typeAttaque,
    required this.degats,
    required this.initiative,
    required this.coutRessources,
    required this.tempsProduction,
    // Paramètres pour les capacités spéciales
  });

  // Méthodes (actions que l'anticorps peut faire)
  // Par exemple: attaquer un pathogène, utiliser une capacité spéciale
  // On les ajoutera plus tard.

  // Méthode pour subir des dégâts
  void subirDegats(double degatsSubis) {
    // Les anticorps n'ont pas d'armure ou de faiblesses/résistances spécifiques
    // pour l'instant, on applique les dégâts directement.
    pv -= degatsSubis;
    if (pv < 0) pv = 0;
    print('Anticorps $id subit $degatsSubis dégâts. PV restants: $pv');
  }

  // Méthode pour attaquer un pathogène
  // On ajoutera la logique de ciblage et d'interaction avec le pathogène plus tard
  void attaquer() {
    print('Anticorps $id attaque avec type $typeAttaque, inflige $degats dégâts.');
    // La logique de calcul des dégâts sur la cible sera dans CombatManager ou ici avec une référence à la cible
  }

  // Méthode pour convertir un objet Anticorps en Map (pour le stocker dans Firestore/Hive)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'pv': pv,
      'maxPv': maxPv,
      'typeAttaque': typeAttaque,
      'degats': degats,
      'initiative': initiative,
      'coutRessources': coutRessources,
      'tempsProduction': tempsProduction,
      // Attributs des capacités spéciales
    };
  }

  // Méthode de classe (static) pour créer un objet Anticorps à partir d'une Map
  static Anticorps fromJson(Map<String, dynamic> json) {
    return Anticorps(
      id: json['id'],
      type: json['type'],
      pv: json['pv'].toDouble(),
      maxPv: json['maxPv'].toDouble(),
      typeAttaque: json['typeAttaque'],
      degats: json['degats'].toDouble(),
      initiative: json['initiative'],
      coutRessources: json['coutRessources'].toDouble(),
      tempsProduction: json['tempsProduction'],
      // Lecture des attributs des capacités spéciales
    );
  }
}