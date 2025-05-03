class RessourcesDefensives {
  double energie;
  double bioMateriaux;
  // Ajoute d'autres types de ressources si besoin

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

  // Méthodes similaires pour les autres ressources
  void ajouterBioMateriaux(double montant) {
    bioMateriaux += montant;
  }

  void retirerBioMateriaux(double montant) {
    bioMateriaux -= montant;
    if (bioMateriaux < 0) bioMateriaux = 0;
  }

  // Méthode pour la régénération passive (peut-être appelée périodiquement)
  void regenererPassif() {
    // Exemple simple de régénération
    energie += 5.0; // Régénère 5 énergie par cycle
    bioMateriaux += 2.0; // Régénère 2 bio-matériaux par cycle
    // Ajouter la logique pour les taux de régénération améliorés par la recherche
  }

  // Méthode pour vérifier si on a assez de ressources pour une action (ex: produire un anticorps)
  bool canAfford({double energieCost = 0, double bioMateriauxCost = 0}) {
    return energie >= energieCost && bioMateriaux >= bioMateriauxCost;
  }


  // Méthode pour convertir en Map pour Firestore/Hive
  Map<String, dynamic> toJson() {
    return {
      'energie': energie,
      'bioMateriaux': bioMateriaux,
      // Autres ressources
    };
  }

  // Méthode pour créer un objet à partir d'une Map
  static RessourcesDefensives fromJson(Map<String, dynamic> json) {
    return RessourcesDefensives(
      energie: json['energie'].toDouble(),
      bioMateriaux: json['bioMateriaux'].toDouble(),
      // Autres ressources
    );
  }
}