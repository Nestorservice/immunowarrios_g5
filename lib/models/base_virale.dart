// lib/models/base_virale.dart
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

  // Méthode pour ajouter un pathogène à la base (sera remplacée par copyWith dans l'UI)
  // Conserver pour d'autres usages internes si nécessaire
  void ajouterPathogene(AgentPathogene pathogene) {
    // Cette méthode modifie l'objet existant. Pour Riverpod/Firebase,
    // il est souvent mieux de créer une nouvelle instance via copyWith.
    // Cependant, elle reste fonctionnelle si elle est utilisée ailleurs.
    pathogenes.add(pathogene);
  }

  // Méthode pour retirer un pathogène (sera remplacée par copyWith dans l'UI)
  // Conserver pour d'autres usages internes si nécessaire
  void retirerPathogene(String pathogeneId) {
    // Comme pour ajouterPathogene, préférer copyWith dans l'UI.
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
      // Attributs des défenses passives (à ajouter ici si vous en avez)
    };
  }

  // Méthode de classe (static) pour créer un objet BaseVirale à partir d'une Map
  static BaseVirale fromJson(Map<String, dynamic> json) {
    return BaseVirale(
      id: json['id'],
      nom: json['nom'],
      createurId: json['createurId'],
      // CORRECTION ICI : Désérialisation correcte des pathogènes
      pathogenes: (json['pathogenes'] as List<dynamic>?)
          ?.map((item) => AgentPathogene.fromMap(item as Map<String, dynamic>))
          .whereType<AgentPathogene>() // Filtre les nulls si fromMap retourne null
          .toList() ?? [],
    );
  }

  // **** NOUVELLE MÉTHODE copyWith ****
  BaseVirale copyWith({
    String? id,
    String? nom,
    String? createurId,
    List<AgentPathogene>? pathogenes,
  }) {
    return BaseVirale(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      createurId: createurId ?? this.createurId,
      pathogenes: pathogenes ?? this.pathogenes,
    );
  }
// **********************************
}