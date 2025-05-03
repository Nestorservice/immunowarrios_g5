import 'package:hive/hive.dart'; // <-- AJOUTE CET IMPORT

part 'laboratoire_recherche.g.dart';

// **AJOUTE CETTE LIGNE AVANT LA CLASSE**
@HiveType(typeId: 1) // Utilise le prochain typeId disponible
class LaboratoireRecherche {
  // **AJOUTE CETTE LIGNE AVANT CHAQUE ATTRIBUT À STOCKER**
  @HiveField(0)
  double pointsRecherche;

  @HiveField(1)
  final List<String> recherchesDebloquees;

  LaboratoireRecherche({
    this.pointsRecherche = 0.0,
    List<String>? recherchesDebloquees,
  }) : recherchesDebloquees = recherchesDebloquees ?? [];

  // ... (méthodes existantes) ...

  // Méthode pour convertir en Map (reste la même)
  Map<String, dynamic> toJson() {
    return {
      'pointsRecherche': pointsRecherche,
      'recherchesDebloquees': recherchesDebloquees,
    };
  }

  // Méthode pour créer un objet à partir d'une Map (reste la même)
  static LaboratoireRecherche fromJson(Map<String, dynamic> json) {
    return LaboratoireRecherche(
      pointsRecherche: json['pointsRecherche'].toDouble(),
      recherchesDebloquees: List<String>.from(json['recherchesDebloquees'] ?? []),
    );
  }
}