import 'package:hive_flutter/hive_flutter.dart';
import '../models/ressources_defensives.dart'; // Importe les modèles stockés dans Hive
import '../models/laboratoire_recherche.dart';
import '../models/memoire_immunitaire.dart';

// Les noms des boîtes que nous avons ouverts dans main.dart
const String resourcesBoxName = 'resourcesBox';
const String researchBoxName = 'researchBox';
const String immuneMemoryBoxName = 'immuneMemoryBox';

class HiveService {

  // Méthode pour obtenir la boîte des ressources
  Box<RessourcesDefensives> get resourcesBox => Hive.box<RessourcesDefensives>(resourcesBoxName);
  // Note: resourcesBox.isOpen pour vérifier si la boîte est ouverte

  // Méthode pour obtenir la boîte de recherche
  Box<LaboratoireRecherche> get researchBox => Hive.box<LaboratoireRecherche>(researchBoxName);

  // Méthode pour obtenir la boîte de mémoire immunitaire
  Box<MemoireImmunitaire> get immuneMemoryBox => Hive.box<MemoireImmunitaire>(immuneMemoryBoxName);


  // --- Fonctions de sauvegarde dans Hive ---

  // Sauvegarde les ressources de l'utilisateur (en utilisant une clé fixe, par ex. l'UID de l'utilisateur)
  Future<void> saveResources(String userId, RessourcesDefensives resources) async {
    // Dans une base de données clé-valeur, on stocke un objet (la valeur) sous une clé (souvent une String ou un int)
    await resourcesBox.put(userId, resources); // Met l'objet 'resources' dans la boîte sous la clé 'userId'
    print('Ressources sauvegardées dans Hive pour $userId');
  }

  // Sauvegarde l'état de la recherche
  Future<void> saveResearch(String userId, LaboratoireRecherche research) async {
    await researchBox.put(userId, research);
    print('Recherche sauvegardée dans Hive pour $userId');
  }

  // Sauvegarde la mémoire immunitaire
  Future<void> saveImmuneMemory(String userId, MemoireImmunitaire immuneMemory) async {
    await immuneMemoryBox.put(userId, immuneMemory);
    print('Mémoire immunitaire sauvegardée dans Hive pour $userId');
  }


  // --- Fonctions de lecture depuis Hive ---

  // Lit les ressources de l'utilisateur depuis Hive
  RessourcesDefensives? getResources(String userId) {
    // get(userId) essaie de trouver une valeur associée à la clé 'userId'
    // Si la clé n'existe pas, ça retourne null
    final resources = resourcesBox.get(userId);
    if (resources != null) {
      print('Ressources lues depuis Hive pour $userId');
    } else {
      print('Ressources non trouvées dans Hive pour $userId');
    }
    return resources;
  }

  // Lit l'état de la recherche depuis Hive
  LaboratoireRecherche? getResearch(String userId) {
    final research = researchBox.get(userId);
    if (research != null) {
      print('Recherche lue depuis Hive pour $userId');
    } else {
      print('Recherche non trouvée dans Hive pour $userId');
    }
    return research;
  }

  // Lit la mémoire immunitaire depuis Hive
  MemoireImmunitaire? getImmuneMemory(String userId) {
    final immuneMemory = immuneMemoryBox.get(userId);
    if (immuneMemory != null) {
      print('Mémoire immunitaire lue depuis Hive pour $userId');
    } else {
      print('Mémoire immunitaire non trouvée dans Hive pour $userId');
    }
    return immuneMemory;
  }

  // --- Fonction de nettoyage (utile pour la déconnexion complète ou la suppression de compte) ---
  Future<void> deleteUserData(String userId) async {
    await resourcesBox.delete(userId);
    await researchBox.delete(userId);
    await immuneMemoryBox.delete(userId);
    print('Données utilisateur $userId supprimées de Hive.');
  }

// TODO: Ajouter des fonctions pour stocker/lire l'historique de combat
}