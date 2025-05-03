import 'agent_pathogene.dart';

class Bacterie extends AgentPathogene {
  // Attributs spécifiques aux Bactéries (s'il y en a, ex: résistance accrue)

  Bacterie({
    required String id,
    required double pv,
    required double maxPv,
    required double armure,
    required String typeAttaque,
    required double degats,
    required int initiative,
    Map<String, double> faiblesses = const {},
    // Ajoute ici des paramètres pour les attributs spécifiques de la Bactérie si besoin
  }) : super(
    id: id,
    type: 'Bacterie', // Le type est fixe
    pv: pv,
    maxPv: maxPv,
    armure: armure,
    typeAttaque: typeAttaque,
    degats: degats,
    initiative: initiative,
    faiblesses: faiblesses,
  );

  // Implémentation de la méthode abstraite subirDegats (peut-être différente pour les Bactéries)
  @override
  void subirDegats(double degatsSubis, String typeAttaque) {
    // Logique de calcul des dégâts spécifique aux Bactéries (ex: résistance de base plus élevée)
    double multiplicateurFaiblesse = faiblesses[typeAttaque] ?? 1.0;
    // Une idée: les bactéries ignorent peut-être une partie des dégâts si l'armure est très haute?
    double degatsFinaux = (degatsSubis - armure).clamp(0, double.infinity) * multiplicateurFaiblesse;
    pv -= degatsFinaux;
    if (pv < 0) pv = 0;
    print('Bacterie $id subit $degatsFinaux dégâts ($typeAttaque). PV restants: $pv');
    // Ajouter ici la logique de capacité spéciale passive si une Bactérie en a une
  }

  // Implémentation de la méthode abstraite attaquer (peut-être différente pour les Bactéries)
  @override
  void attaquer() {
    // Logique d'attaque spécifique aux Bactéries (ex: attaque empoisonnée)
    print('Bacterie $id attaque avec type $typeAttaque, inflige $degats dégâts.');
    // Ajouter ici la logique de capacité spéciale active si une Bactérie en a une
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
      // Ajoute ici les attributs spécifiques de la Bactérie si tu en as
    };
  }

  // Méthode de classe (static) pour créer un objet Bacterie à partir d'une Map
  static Bacterie fromJson(Map<String, dynamic> json) {
    return Bacterie(
      id: json['id'],
      pv: json['pv'].toDouble(),
      maxPv: json['maxPv'].toDouble(),
      armure: json['armure'].toDouble(),
      typeAttaque: json['typeAttaque'],
      degats: json['degats'].toDouble(),
      initiative: json['initiative'],
      faiblesses: Map<String, double>.from(json['faiblesses'] ?? {}),
      // Ajoute ici la lecture des attributs spécifiques de la Bactérie
    );
  }
}