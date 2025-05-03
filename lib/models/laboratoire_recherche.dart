// On aura besoin de définir ce qu'est une "Recherche" déblocable.
// Pour l'instant, on peut juste stocker des IDs ou des noms de recherches complétées
// et les points de recherche actuels du joueur.

class LaboratoireRecherche {
  double pointsRecherche;
  final List<String> recherchesDebloquees; // IDs ou noms des recherches que le joueur possède

  LaboratoireRecherche({
    this.pointsRecherche = 0.0,
    List<String>? recherchesDebloquees,
  }) : recherchesDebloquees = recherchesDebloquees ?? [];

  // Méthode pour ajouter des points de recherche (gagnés en combat, etc.)
  void ajouterPoints(double montant) {
    pointsRecherche += montant;
  }

  // Méthode pour lancer/compléter une recherche (à implémenter plus tard)
  // Elle vérifierait si le joueur a assez de points, retirerait les points, et ajouterait la recherche à la liste.
  // bool lancerRecherche(String rechercheId, double cout) { ... }

  // Méthode pour vérifier si une recherche est débloquée
  bool isRechercheDebloquee(String rechercheId) {
    return recherchesDebloquees.contains(rechercheId);
  }

  // Méthode pour convertir en Map pour Firestore/Hive
  Map<String, dynamic> toJson() {
    return {
      'pointsRecherche': pointsRecherche,
      'recherchesDebloquees': recherchesDebloquees,
    };
  }

  // Méthode pour créer un objet à partir d'une Map
  static LaboratoireRecherche fromJson(Map<String, dynamic> json) {
    return LaboratoireRecherche(
      pointsRecherche: json['pointsRecherche'].toDouble(),
      recherchesDebloquees: List<String>.from(json['recherchesDebloquees'] ?? []),
    );
  }
}