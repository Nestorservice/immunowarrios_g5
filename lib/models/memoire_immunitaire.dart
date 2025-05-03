// On pourrait stocker des identifiants ou des "signatures" de pathogènes
// Pour commencer, on peut stocker juste une liste des types de pathogènes rencontrés,
// ou des ID si chaque instance de pathogène avait un ID unique persistant.
// Le cahier parle de "signatures" et vulnérabilité aux mutations.

// Une approche simple: stocker une liste de strings représentant les types de pathogènes connus
// et peut-être une Map pour les bonus spécifiques par type.

class MemoireImmunitaire {
  // Liste des types de pathogènes dont on a une "signature" de base
  final List<String> typesConnus;

  // Bonus acquis par type (peut-être via R&D ou combats répétés)
  // Ex: {'Virus': 0.1, 'Bacterie': 0.05} pour un bonus de dégâts de 10% contre les Virus
  final Map<String, double> bonusEfficacite;

  // Mécanisme pour les mutations (simplifié pour l'instant)
  // On pourrait avoir un compteur ou un indicateur ici.

  MemoireImmunitaire({
    List<String>? typesConnus,
    Map<String, double>? bonusEfficacite,
  }) : typesConnus = typesConnus ?? [],
        bonusEfficacite = bonusEfficacite ?? {};


  // Méthode pour ajouter une nouvelle "signature" (un type de pathogène)
  void ajouterSignature(String typePathogene) {
    if (!typesConnus.contains(typePathogene)) {
      typesConnus.add(typePathogene);
      print('Nouvelle signature immunitaire acquise pour les types $typePathogene.');
      // On pourrait déclencher l'ajout d'un petit bonus de base ici
    }
  }

  // Méthode pour obtenir le bonus contre un type de pathogène donné
  double getBonusContre(String typePathogene) {
    // Si le type est connu, on cherche un bonus spécifique, sinon bonus de base (peut-être 0 ou petit)
    if (typesConnus.contains(typePathogene)) {
      return bonusEfficacite[typePathogene] ?? 0.0; // Retourne le bonus spécifique ou 0
    }
    return 0.0; // Aucun bonus si le type n'est pas connu
  }

  // Méthode pour améliorer un bonus (via R&D)
  void ameliorerBonus(String typePathogene, double montant) {
    if (typesConnus.contains(typePathogene)) {
      bonusEfficacite[typePathogene] = (bonusEfficacite[typePathogene] ?? 0.0) + montant;
      print('Bonus contre $typePathogene amélioré ! Nouveau bonus: ${bonusEfficacite[typePathogene]}');
    }
  }

  // Méthode pour gérer l'impact des mutations (à implémenter plus tard)
  // Par exemple, une mutation pourrait temporairement annuler le bonus ou le réduire

  // Méthode pour convertir en Map pour Firestore/Hive
  Map<String, dynamic> toJson() {
    return {
      'typesConnus': typesConnus,
      'bonusEfficacite': bonusEfficacite,
    };
  }

  // Méthode pour créer un objet à partir d'une Map
  static MemoireImmunitaire fromJson(Map<String, dynamic> json) {
    return MemoireImmunitaire(
      typesConnus: List<String>.from(json['typesConnus'] ?? []),
      bonusEfficacite: Map<String, double>.from(json['bonusEfficacite'] ?? {}),
    );
  }
}