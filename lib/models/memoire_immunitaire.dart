import 'package:hive/hive.dart'; // <-- AJOUTE CET IMPORT

part 'memoire_immunitaire.g.dart';

// **AJOUTE CETTE LIGNE AVANT LA CLASSE**
@HiveType(typeId: 2) // Utilise le prochain typeId disponible
class MemoireImmunitaire {
  // **AJOUTE CETTE LIGNE AVANT CHAQUE ATTRIBUT À STOCKER**
  @HiveField(0)
  final List<String> typesConnus;

  @HiveField(1)
  final Map<String, double> bonusEfficacite;

  MemoireImmunitaire({
    List<String>? typesConnus,
    Map<String, double>? bonusEfficacite,
  }) : typesConnus = typesConnus ?? [],
        bonusEfficacite = bonusEfficacite ?? {};

  // ... (méthodes existantes) ...

  // Méthode pour convertir en Map (reste la même)
  Map<String, dynamic> toJson() {
    return {
      'typesConnus': typesConnus,
      'bonusEfficacite': bonusEfficacite,
    };
  }

  // Méthode pour créer un objet à partir d'une Map (reste la même)
  static MemoireImmunitaire fromJson(Map<String, dynamic> json) {
    return MemoireImmunitaire(
      typesConnus: List<String>.from(json['typesConnus'] ?? []),
      bonusEfficacite: Map<String, double>.from(json['bonusEfficacite'] ?? {}),
    );
  }
}
// **AJOUTE CETTE LIGNE À LA FIN DU FICHIER**
