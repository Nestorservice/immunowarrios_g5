// **CORRECTION : Déplacer la directive 'part' ici, juste après les imports**
import 'package:hive/hive.dart'; // Importe Hive

part 'ressources_defensives.g.dart';

// **Annotations pour Hive**
@HiveType(typeId: 0) // typeId doit être unique pour chaque classe
class RessourcesDefensives {
  // **Annotations pour HiveFields**
  @HiveField(0) // fieldId doit être unique DANS CETTE CLASSE
  double energie;

  @HiveField(1) // fieldId suivant
  double bioMateriaux;

  // Ajoute d'autres types de ressources si besoin avec @HiveField(2), etc.

  RessourcesDefensives({
    this.energie = 100.0, // Valeurs de départ par défaut
    this.bioMateriaux = 50.0,
  });

  // Méthodes pour ajouter/retirer des ressources, gérer la régénération passive
  void ajouterEnergie(double montant) {
    energie += montant;
    // Optionnel: ajouter une limite maximale
  }

  void retirerEnergie(double montant) {
    energie -= montant;
    if (energie < 0) energie = 0; // Ne pas descendre en dessous de zéro
  }

  void ajouterBioMateriaux(double montant) {
    bioMateriaux += montant;
  }

  void retirerBioMateriaux(double montant) {
    bioMateriaux -= montant;
    if (bioMateriaux < 0) bioMateriaux = 0;
  }

  void regenererPassif() {
    // Exemple simple de régénération
    energie += 5.0; // Régénère 5 énergie par cycle
    bioMateriaux += 2.0; // Régénère 2 bio-matériaux par cycle
  }

  bool canAfford({double energieCost = 0, double bioMateriauxCost = 0}) {
    return energie >= energieCost && bioMateriaux >= bioMateriauxCost;
  }


  // Méthode pour convertir en Map pour Firestore (reste la même)
  Map<String, dynamic> toJson() {
    return {
      'energie': energie,
      'bioMateriaux': bioMateriaux,
    };
  }

  // Méthode pour créer un objet à partir d'une Map (reste la même, utile pour Firestore)
  static RessourcesDefensives fromJson(Map<String, dynamic> json) {
    return RessourcesDefensives(
      energie: json['energie'].toDouble(),
      bioMateriaux: json['bioMateriaux'].toDouble(),
    );
  }
}