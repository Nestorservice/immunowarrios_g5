// lib/models/laboratoire_recherche.dart
import 'package:hive/hive.dart';

part 'laboratoire_recherche.g.dart';

@HiveType(typeId: 1)
class LaboratoireRecherche {
  @HiveField(0)
  double pointsRecherche;

  @HiveField(1)
  final List<String> recherchesDebloquees;

  LaboratoireRecherche({
    this.pointsRecherche = 0.0,
    List<String>? recherchesDebloquees,
  }) : recherchesDebloquees = recherchesDebloquees ?? [];

  // Méthode copyWith pour créer une nouvelle instance avec des modifications
  LaboratoireRecherche copyWith({
    double? pointsRecherche,
    List<String>? recherchesDebloquees,
  }) {
    return LaboratoireRecherche(
      pointsRecherche: pointsRecherche ?? this.pointsRecherche,
      recherchesDebloquees: recherchesDebloquees ?? this.recherchesDebloquees,
    );
  }

  // Méthode pour convertir en Map pour Firestore
  Map<String, dynamic> toJson() {
    return {
      'pointsRecherche': pointsRecherche,
      'recherchesDebloquees': recherchesDebloquees,
    };
  }

  // Méthode pour créer un objet à partir d'une Map (ajout de null-safety)
  static LaboratoireRecherche fromJson(Map<String, dynamic> json) {
    return LaboratoireRecherche(
      pointsRecherche: (json['pointsRecherche'] as num?)?.toDouble() ?? 0.0,
      recherchesDebloquees: List<String>.from(json['recherchesDebloquees'] ?? []),
    );
  }
}