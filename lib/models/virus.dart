import 'agent_pathogene.dart'; // Importe la classe mère

class Virus extends AgentPathogene {
  // Attributs spécifiques aux Virus (s'il y en a)
  // Par exemple: la probabilité de mutation

  Virus({
    required String id,
    required double pv,
    required double maxPv,
    required double armure,
    required String typeAttaque,
    required double degats,
    required int initiative,
    Map<String, double> faiblesses = const {},
    // Ajoute ici des paramètres pour les attributs spécifiques du Virus si besoin
  }) : super( // Appelle le constructeur de la classe AgentPathogene
    id: id,
    type: 'Virus', // Le type est fixe pour cette classe
    pv: pv,
    maxPv: maxPv,
    armure: armure,
    typeAttaque: typeAttaque,
    degats: degats,
    initiative: initiative,
    faiblesses: faiblesses,
  );

  // Implémentation de la méthode abstraite subirDegats
  @override
  void subirDegats(double degatsSubis, String typeAttaque) {
    // Logique de calcul des dégâts spécifique aux Virus, si différente
    // Pour commencer, on fait simple : réduction par armure, puis application.
    double multiplicateurFaiblesse = faiblesses[typeAttaque] ?? 1.0; // 1.0 si pas de faiblesse/résistance
    double degatsFinaux = (degatsSubis - armure).clamp(0, double.infinity) * multiplicateurFaiblesse; // degats ne peuvent pas être négatifs
    pv -= degatsFinaux;
    if (pv < 0) pv = 0;
    print('Virus $id subit $degatsFinaux dégâts ($typeAttaque). PV restants: $pv');
    // Ajouter ici la logique de capacité spéciale passive si un Virus en a une liée aux dégâts subis
  }

  // Implémentation de la méthode abstraite attaquer
  @override
  void attaquer() {
    // Logique d'attaque spécifique aux Virus
    print('Virus $id attaque avec type $typeAttaque, inflige $degats dégâts.');
    // Ajouter ici la logique de capacité spéciale active si un Virus en a une
  }

  // Implémentation de la méthode abstraite toJson
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'pv': pv,
      'maxPv': maxPv,
      'armure': armure,
      'typeAttaque': typeAttaque,
      'degats': degats,
      'initiative': initiative,
      'faiblesses': faiblesses,
      // Ajoute ici les attributs spécifiques du Virus si tu en as
    };
  }

  // Méthode de classe (static) pour créer un objet Virus à partir d'une Map (Firestore/Hive)
  static Virus fromJson(Map<String, dynamic> json) {
    return Virus(
      id: json['id'],
      pv: json['pv'].toDouble(),
      maxPv: json['maxPv'].toDouble(),
      armure: json['armure'].toDouble(),
      typeAttaque: json['typeAttaque'],
      degats: json['degats'].toDouble(),
      initiative: json['initiative'],
      faiblesses: Map<String, double>.from(json['faiblesses'] ?? {}),
      // Ajoute ici la lecture des attributs spécifiques du Virus
    );
  }
}