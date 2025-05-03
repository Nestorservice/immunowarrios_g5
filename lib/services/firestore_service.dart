import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ressources_defensives.dart';
import '../models/laboratoire_recherche.dart';
import '../models/memoire_immunitaire.dart';
import '../models/base_virale.dart';
import '../models/agent_pathogene.dart'; // Important pour AgentPathogene.fromMap

// Classe pour gérer les interactions avec Firestore
class FirestoreService {
  // On obtient une instance de FirebaseFirestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Fonctions pour les données utilisateur ---

  // Méthode pour créer le document utilisateur initial dans la collection 'users'
  Future<void> createUserProfile({
    required String userId,
    required String email,
    // Ajoutez d'autres données initiales si nécessaire
  }) async {
    // Crée les objets modèles avec leurs valeurs initiales
    final initialResources = RessourcesDefensives();
    final initialResearch = LaboratoireRecherche();
    final initialImmuneMemory = MemoireImmunitaire();

    // Crée une Map représentant le document utilisateur
    // Utilise les méthodes toJson() de tes modèles
    final userData = {
      'email': email,
      'createdAt': Timestamp.now(), // Firestore a un type Timestamp
      'resources': initialResources.toJson(), // Convertit l'objet en Map
      'research': initialResearch.toJson(),
      'immuneMemory': initialImmuneMemory.toJson(),
      // Ajoute ici d'autres champs utilisateur (ex: nom de joueur si tu en ajoutes un)
    };

    // Ajoute le document à la collection 'users' avec l'UID de l'utilisateur comme ID du document
    await _db.collection('users').doc(userId).set(userData);
    print('Profil utilisateur créé/mis à jour pour $userId');
  }

  // Méthode pour obtenir le Stream des données de l'utilisateur actuel
  Stream<Map<String, dynamic>?> streamUserProfile(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return data;
    });
  }

  // Méthode pour mettre à jour des champs spécifiques du profil utilisateur
  Future<void> updateUserProfile(String userId, Map<String, dynamic> dataToUpdate) async {
    await _db.collection('users').doc(userId).update(dataToUpdate);
    print('Profil utilisateur $userId mis à jour : $dataToUpdate');
  }

  // Méthode pour lire les données utilisateur une seule fois (pas en temps réel)
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      print('Profil utilisateur $userId lu (une seule fois).');
      return doc.data();
    } else {
      print('Profil utilisateur $userId introuvable.');
      return null;
    }
  }


  // --- Fonctions pour les Bases Virales ---

  // Méthode pour créer ou mettre à jour la base virale du joueur
  Future<void> savePlayerBase({required String userId, required BaseVirale base}) async {
    await _db.collection('viralBases').doc(userId).set(base.toJson());
    print('Base virale du joueur $userId sauvegardée.');
  }

  // Méthode pour obtenir le Stream de TOUTES les bases virales (pour le scanner)
  Stream<List<BaseVirale>> streamAllViralBases() {
    return _db.collection('viralBases').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final List<AgentPathogene> pathogensList = (data['pathogenes'] as List<dynamic>?)
            ?.map((item) {
          if (item is Map<String, dynamic>) {
            // Appelle la méthode fromMap de AgentPathogene pour désérialiser
            return AgentPathogene.fromMap(item);
          }
          print('Avertissement de désérialisation: Élément de pathogène inattendu non-Map.');
          return null;
        })
            .whereType<AgentPathogene>()
            .toList() ?? [];

        return BaseVirale(
          id: doc.id,
          nom: data['nom'] ?? 'Base inconnue',
          createurId: data['createurId'],
          pathogenes: pathogensList,
        );
      }).toList();
    });
  }

  // Méthode pour obtenir une BaseVirale spécifique
  Future<BaseVirale?> getViralBase(String baseId) async {
    final doc = await _db.collection('viralBases').doc(baseId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data == null) return null;

      final List<AgentPathogene> pathogensList = (data['pathogenes'] as List<dynamic>?)
          ?.map((item) {
        if (item is Map<String, dynamic>) {
          return AgentPathogene.fromMap(item);
        }
        print('Avertissement de désérialisation: Élément de pathogène inattendu non-Map.');
        return null;
      })
          .whereType<AgentPathogene>()
          .toList() ?? [];

      return BaseVirale(
        id: doc.id,
        nom: data['nom'] ?? 'Base inconnue',
        createurId: data['createurId'],
        pathogenes: pathogensList,
      );
    } else {
      print('Base virale $baseId introuvable.');
      return null;
    }
  }


// --- Fonctions pour l'Historique des combats (à implémenter plus tard) ---

}