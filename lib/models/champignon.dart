import 'agent_pathogene.dart';

class Champignon extends AgentPathogene {
  // Attributs spécifiques aux Champignons (s'il y en a, ex: résistance aux dégâts chimiques)

  Champignon({
    required String id,
    required double pv,
    required double maxPv,
    required double armure,
    required String typeAttaque,
    required double degats,
    required int initiative,
    Map<String, double> faiblesses = const {},
    // Ajoute ici des paramètres pour les attributs spécifiques du Champignon si besoin
  }) : super(
    id: id,
    type: 'Champignon', // Le type est fixe
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
    // Logique de calcul des dégâts spécifique aux Champignons
    double multiplicateurFaiblesse = faiblesses[typeAttaque] ?? 1.0;
    // Une idée: les champignons ont une forte résistance chimique par défaut?
    double degatsFinaux = (degatsSubis - armure).clamp(0, double.infinity) * multiplicateurFaiblesse;
    pv -= degatsFinaux;
    if (pv < 0) pv = 0;
    print('Champignon $id subit $degatsFinaux dégâts ($typeAttaque). PV restants: $pv');
    // Ajouter ici la logique de capacité spéciale passive si un Champignon en a une
  }

  // Implémentation de la méthode abstraite attaquer
  @override
  void attaquer() {
    // Logique d'attaque spécifique aux Champignons (ex: attaque de zone via spores)
    print('Champignon $id attaque avec type $typeAttaque, inflige $degats dégâts.');
    // Ajouter ici la logique de capacité spéciale active si un Champignon en a une
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
      // Ajoute ici les attributs spécifiques du Champignon si tu en as
    };
  }

  // Méthode de classe (static) pour créer un objet Champignon à partir d'une Map
  static Champignon fromJson(Map<String, dynamic> json) {
    return Champignon(
      id: json['id'],
      pv: json['pv'].toDouble(),
      maxPv: json['maxPv'].toDouble(),
      armure: json['armure'].toDouble(),
      typeAttaque: json['typeAttaque'],
      degats: json['degats'].toDouble(),
      initiative: json['initiative'],
      faiblesses: Map<String, double>.from(json['faiblesses'] ?? {}),
      // Ajoute ici la lecture des attributs spécifiques du Champignon
    );
  }
}

// Note importante: Pour pouvoir créer dynamiquement le bon type de pathogène
// à partir de Firestore (Virus, Bacterie ou Champignon) en lisant le champ 'type',
// on aura besoin d'une fonction "factory" ou "fromJson" plus globale,
// ou d'utiliser un package comme json_serializable plus tard.
// Pour l'instant, la méthode fromJson dans chaque classe est un début.
// Une approche simple pour le TP pourrait être une fonction dans AgentPathogene
// qui regarde le type et appelle le bon fromJson:
/*
static AgentPathogene? fromMap(Map<String, dynamic> map) {
  switch (map['type']) {
    case 'Virus': return Virus.fromJson(map);
    case 'Bacterie': return Bacterie.fromJson(map);
    case 'Champignon': return Champignon.fromJson(map);
    default: return null;
  }
}
*/
// On mettra ça en place quand on gérera la lecture depuis Firestore.