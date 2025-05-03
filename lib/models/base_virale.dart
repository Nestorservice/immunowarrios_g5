import 'agent_pathogene.dart'; // On importe AgentPathogene pour pouvoir stocker une liste de pathogènes

class BaseVirale {
  final String id; // ID unique de la base (peut être l'ID de l'utilisateur si c'est sa base)
  final String nom; // Nom de la base (ex: "Base de Roslyne", "Nid de Virus Alpha")
  final String createurId; // L'ID de l'utilisateur qui possède cette base (utile pour attaquer les bases d'autres joueurs)
  final List<AgentPathogene> pathogenes; // La liste des pathogènes dans cette base
  // Ajoute ici des défenses passives optionnelles (ex: MurailleProteique)

  BaseVirale({
    required this.id,
    required this.nom,
    required this.createurId,
    List<AgentPathogene>? pathogenes, // Liste optionnelle
    // Paramètres pour les défenses passives
  }) : pathogenes = pathogenes ?? [];

  // Méthode pour ajouter un pathogène à la base
  void ajouterPathogene(AgentPathogene pathogene) {
    pathogenes.add(pathogene);
  }

  // Méthode pour retirer un pathogène (ex: après un combat ou si le joueur le retire)
  void retirerPathogene(String pathogeneId) {
    pathogenes.removeWhere((p) => p.id == pathogeneId);
  }

  // Méthode pour convertir en Map pour Firestore (utile pour sauvegarder la base du joueur)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'createurId': createurId,
      // Convertir la liste de pathogènes en liste de Maps
      'pathogenes': pathogenes.map((p) => p.toJson()).toList(),
      // Attributs des défenses passives
    };
  }

  // Méthode de classe (static) pour créer un objet BaseVirale à partir d'une Map
  static BaseVirale fromJson(Map<String, dynamic> json) {
    // Pour désérialiser la liste de pathogènes, on a besoin de la fonction fromMap
    // mentionnée dans agent_pathogene.dart (ou une logique similaire)
    // On utilisera le Helper fromMap quand on chargera depuis Firestore.
    return BaseVirale(
      id: json['id'],
      nom: json['nom'],
      createurId: json['createurId'],
      // Ici, on doit convertir la liste de Maps en liste d'objets AgentPathogene
      // On fera ça quand on chargera depuis Firestore/Hive.
      // Pour l'instant, on peut mettre une liste vide ou gérer la désérialisation
      // via une fonction helper.
      // Exemple simple (nécessite la fonction AgentPathogene.fromMap):
      // pathogenes: (json['pathogenes'] as List<dynamic>?)
      //     ?.map((item) => AgentPathogene.fromMap(item as Map<String, dynamic>))
      //     .whereType<AgentPathogene>() // Filtre les null si fromMap retourne null
      //     .toList() ?? [],
      pathogenes: [], // Placeholder pour l'instant, on gérera la désérialisation plus tard
    );
  }
}