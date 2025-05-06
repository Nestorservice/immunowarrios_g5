import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ressources_defensives.dart';
import '../models/laboratoire_recherche.dart';
import '../models/memoire_immunitaire.dart';
import '../models/base_virale.dart';
import '../models/agent_pathogene.dart'; // Important pour AgentPathogene.fromMap
// Importe les classes spécifiques des pathogènes car fromMap peut les utiliser
import '../models/virus.dart';
import '../models/bacterie.dart';
import '../models/champignon.dart'; // Assure-toi que Champignon.dart existe si tu l'utilises


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
    final initialResources = RessourcesDefensives();
    final initialResearch = LaboratoireRecherche();
    final initialImmuneMemory = MemoireImmunitaire();

    final userData = {
      'email': email,
      'createdAt': Timestamp.now(),
      'resources': initialResources.toJson(),
      'research': initialResearch.toJson(),
      'immuneMemory': initialImmuneMemory.toJson(),
    };

    await _db.collection('users').doc(userId).set(userData);
    print('FirestoreService: Profil utilisateur créé/mis à jour pour $userId');
  }

  // Méthode pour obtenir le Stream des données de l'utilisateur actuel
  Stream<Map<String, dynamic>?> streamUserProfile(String userId) {
    // snapshots() sur un document retourne un Stream de DocumentSnapshot.
    // Chaque fois que le document change, un nouveau DocumentSnapshot est émis.
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        // print('FirestoreService: Profil utilisateur $userId introuvable ou vide via stream.');
        return null;
      }
      // print('FirestoreService: Profil utilisateur $userId mis à jour via stream.');
      return data;
    });
  }

  // Méthode pour mettre à jour des champs spécifiques du profil utilisateur
  Future<void> updateUserProfile(String userId, Map<String, dynamic> dataToUpdate) async {
    // update() échouera si le document n'existe pas. set(data, SetOptions(merge: true)) est une alternative sûre.
    await _db.collection('users').doc(userId).update(dataToUpdate);
    print('FirestoreService: Profil utilisateur $userId mis à jour : $dataToUpdate');
  }

  // Méthode pour lire les données utilisateur une seule fois (pas en temps réel)
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      print('FirestoreService: Profil utilisateur $userId lu (une seule fois).');
      return doc.data();
    } else {
      print('FirestoreService: Profil utilisateur $userId introuvable (lecture unique).');
      return null;
    }
  }


  // --- Fonctions pour les Bases Virales ---

  // Méthode pour créer ou mettre à jour la base virale du joueur
  Future<void> savePlayerBase({required String userId, required BaseVirale base}) async {
    // Utilise l'ID du joueur comme ID du document dans la collection viralBases
    await _db.collection('viralBases').doc(userId).set(base.toJson());
    print('FirestoreService: Base virale du joueur $userId sauvegardée.');
  }

  // Méthode pour obtenir le Stream de TOUTES les bases virales (pour le scanner)
  Stream<List<BaseVirale>> streamAllViralBases() {
    print('FirestoreService: Streaming toutes les bases virales...');
    // snapshots() sur la collection retourne un Stream de QuerySnapshot.
    return _db.collection('viralBases').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Désérialisation des pathogènes :
        final List<AgentPathogene> pathogensList = (data['pathogenes'] as List<dynamic>?)
            ?.map((item) {
          if (item is Map<String, dynamic>) {
            return AgentPathogene.fromMap(item); // Appelle notre helper function fromMap
          }
          print('FirestoreService: Avertissement de désérialisation: Élément de pathogène inattendu non-Map lors du stream all bases.');
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

  // **AJOUT IMPORTANT POUR L'ÉTAPE 8 :**
  // Méthode pour obtenir un Stream d'une BaseVirale spécifique (pour la page de détails)
  Stream<BaseVirale?> streamViralBase(String baseId) { // <-- AJOUTE CETTE MÉTHODE
    print('FirestoreService: Streaming la base virale: $baseId');
    // Écoute les snapshots d'un document spécifique dans la collection 'viralBases'
    return _db.collection('viralBases').doc(baseId).snapshots().map((snapshot) { // <-- Utilise .doc(baseId).snapshots()
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        // Désérialisation de la liste de pathogènes, similaire à streamAllViralBases
        final List<AgentPathogene> pathogensList = (data['pathogenes'] as List<dynamic>?)
            ?.map((item) {
          if (item is Map<String, dynamic>) {
            return AgentPathogene.fromMap(item); // Appelle AgentPathogene.fromMap
          }
          print('FirestoreService: Avertissement de désérialisation: Élément de pathogène inattendu non-Map lors du stream d\'une base.');
          return null;
        })
            .whereType<AgentPathogene>()
            .toList() ?? [];

        return BaseVirale(
          id: snapshot.id, // L'ID du document est l'ID de la base
          nom: data['nom'] ?? 'Base inconnue',
          createurId: data['createurId'],
          pathogenes: pathogensList,
        );
      } else {
        // Si le document n'existe pas ou n'a pas de données, émet null
        print('FirestoreService: Base virale $baseId introuvable ou vide via stream.');
        return null;
      }
    });
  }


  // Méthode pour obtenir une BaseVirale spécifique une seule fois (pas en temps réel)
  Future<BaseVirale?> getViralBase(String baseId) async {
    print('FirestoreService: Lecture unique de la base virale: $baseId');
    final doc = await _db.collection('viralBases').doc(baseId).get(); // <-- Utilise .doc(baseId).get()
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      // Désérialisation de la liste de pathogènes
      final List<AgentPathogene> pathogensList = (data['pathogenes'] as List<dynamic>?)
          ?.map((item) {
        if (item is Map<String, dynamic>) {
          return AgentPathogene.fromMap(item);
        }
        print('FirestoreService: Avertissement de désérialisation: Élément de pathogène inattendu non-Map lors de lecture unique d\'une base.');
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
      print('FirestoreService: Base virale $baseId introuvable (lecture unique).');
      return null;
    }
  }


// --- Fonctions pour l'Historique des combats (à implémenter plus tard) ---
// collection 'battles'
// Future<void> saveBattleResult(...)
// Stream<List<Battle>> streamBattleHistory(String userId)...

}