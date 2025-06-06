// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // Importe le package Uuid pour générer des IDs uniques

// Assurez-vous que ces chemins de modèles sont corrects et que les fichiers existent
import '../models/ressources_defensives.dart';
import '../models/laboratoire_recherche.dart';
import '../models/memoire_immunitaire.dart';
import '../models/base_virale.dart';
import '../models/combat_result.dart'; // Assurez-vous que ce fichier définit la classe CombatResult
import '../models/agent_pathogene.dart'; // Important pour AgentPathogene.fromMap
import '../models/virus.dart';
import '../models/bacterie.dart';
import '../models/champignon.dart'; // Assurez-toi que Champignon.dart existe si tu l'utilises

// Classe pour gérer les interactions avec Firestore
class FirestoreService {
  // On obtient une instance de FirebaseFirestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid(); // Instance de Uuid pour générer des IDs

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

    // Utilise SetOptions(merge: true) pour éviter d'écraser des données existantes
    // si cette méthode est appelée plusieurs fois pour le même user (prévient les bugs).
    await _db.collection('users').doc(userId).set(userData, SetOptions(merge: true));
    print('FirestoreService: Profil utilisateur créé/mis à jour pour $userId');

    // **AJOUT CLÉ :** Assure-toi que la base virale est également créée lors de la création du profil.
    await getOrCreatePlayerBase(userId);
    print('FirestoreService: Base virale initialisée lors de la création du profil pour $userId.');
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
    print('FirestoreService: Profil utilisateur $userId mis à jour : $dataToUpdate');
  }

  // Méthode pour lire les données utilisateur une seule fois (pas en temps réel)
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    print('FirestoreService: Lecture unique de profil utilisateur: $userId');
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      print('FirestoreService: Profil utilisateur $userId lu (une seule fois).');
      return doc.data();
    } else {
      print('FirestoreService: Profil utilisateur $userId introuvable (lecture unique).');
      return null;
    }
  }

  // NOUVELLE MÉTHODE : Récupérer les données de recherche de l'utilisateur (une seule fois)
  Future<LaboratoireRecherche?> getUserResearch(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (data.containsKey('research')) {
        return LaboratoireRecherche.fromJson(data['research']);
      }
    }
    return null;
  }

  // --- Fonctions pour les Bases Virales ---

  // Méthode pour créer ou mettre à jour la base virale du joueur
  Future<void> savePlayerBase({required String userId, required BaseVirale base}) async {
    await _db.collection('viralBases').doc(userId).set(base.toJson());
    print('FirestoreService: Base virale du joueur $userId sauvegardée.');
  }

  // Méthode pour obtenir le Stream de TOUTES les bases virales (pour le scanner)
  // J'ai renommé l'ancienne 'streamAllViralBases' en 'streamAllOtherViralBases' pour la clarté
  Stream<List<BaseVirale>> streamAllOtherViralBases(String currentUserId) {
    print('FirestoreService: Streaming toutes les bases virales sauf celle de $currentUserId...');
    return _db.collection('viralBases').where('createurId', isNotEqualTo: currentUserId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final List<AgentPathogene> pathogensList = (data['pathogenes'] as List<dynamic>?)
            ?.map((item) {
          if (item is Map<String, dynamic>) {
            return AgentPathogene.fromMap(item);
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

  // Méthode pour obtenir un Stream d'une BaseVirale spécifique (pour la page de détails)
  Stream<BaseVirale?> streamViralBase(String baseId) {
    print('FirestoreService: Streaming la base virale: $baseId');
    return _db.collection('viralBases').doc(baseId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final List<AgentPathogene> pathogensList = (data['pathogenes'] as List<dynamic>?)
            ?.map((item) {
          if (item is Map<String, dynamic>) {
            return AgentPathogene.fromMap(item);
          }
          print('FirestoreService: Avertissement de désérialisation: Élément de pathogène inattendu non-Map lors du stream d\'une base.');
          return null;
        })
            .whereType<AgentPathogene>()
            .toList() ?? [];

        return BaseVirale(
          id: snapshot.id,
          nom: data['nom'] ?? 'Base inconnue',
          createurId: data['createurId'],
          pathogenes: pathogensList,
        );
      } else {
        print('FirestoreService: Base virale $baseId introuvable ou vide via stream.');
        return null;
      }
    });
  }


  // Méthode pour obtenir une BaseVirale spécifique une seule fois (pas en temps réel)
  Future<BaseVirale?> getViralBase(String baseId) async {
    print('FirestoreService: Lecture unique de la base virale: $baseId');
    final doc = await _db.collection('viralBases').doc(baseId).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
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

  /// Récupère la BaseVirale d'un utilisateur. Si elle n'existe pas,
  /// en crée une par défaut et la sauvegarde dans Firestore avec des pathogènes initiaux.
  Future<BaseVirale> getOrCreatePlayerBase(String userId) async {
    print('FirestoreService: Tentative de récupération ou de création de la base virale pour $userId.');
    BaseVirale? playerBase = await getViralBase(userId);

    if (playerBase == null) {
      print('FirestoreService: Base virale pour $userId non trouvée. Création d\'une base par défaut.');

      // **Définis ici les pathogènes que tu veux pour les nouvelles bases par défaut.**
      final List<AgentPathogene> defaultPathogens = [
        Virus(
          id: _uuid.v4(), // ID unique pour ce pathogène
          pv: 50,
          maxPv: 50,
          armure: 5,
          degats: 10,
          initiative: 15,
          typeAttaque: 'corrosive',
          faiblesses: {'energetique': 0.5, 'physique': 1.5},
        ),
        Bacterie(
          id: _uuid.v4(), // ID unique pour ce pathogène
          pv: 80,
          maxPv: 80,
          armure: 8,
          degats: 12,
          initiative: 10,
          typeAttaque: 'physique',
          faiblesses: {'feu': 1.2, 'froid': 0.8},
        ),
        // Ajoute d'autres pathogènes par défaut ici si tu le souhaites
        // par exemple, un Champignon, ou d'autres types/stats de Virus/Bactérie.
      ];

      playerBase = BaseVirale(
        id: userId,
        nom: 'Base de ' + userId.substring(0, 5), // Nom simple basé sur l'ID
        createurId: userId,
        pathogenes: defaultPathogens, // IMPORTANT : Assigne les pathogènes par défaut
      );

      await savePlayerBase(userId: userId, base: playerBase);
      print('FirestoreService: Base virale par défaut créée et sauvegardée pour $userId avec ${defaultPathogens.length} pathogènes.');
    }
    return playerBase;
  }

  // Méthode pour sauvegarder un résultat de combat
  Future<void> saveCombatResult({required CombatResult combatResult}) async {
    await _db.collection('combatResults').doc(combatResult.id).set(combatResult.toJson());
    print('FirestoreService: Résultat de combat ${combatResult.id} sauvegardé.');
  }

  // NOUVELLE MÉTHODE : Stream les résultats de combat pour un utilisateur (Renommée pour la clarté)
  Stream<List<CombatResult>> streamCombatResults(String userId) {
    return _db
        .collection('combatResults')
        .where('attackerId', isEqualTo: userId) // Filtre par l'ID de l'attaquant (le joueur)
        .orderBy('combatDate', descending: true) // Classe par date du plus récent au plus ancien
        .snapshots()
        .map((snapshot) {
      print('FirestoreService: Nouveaux résultats de combat pour $userId reçus.');
      return snapshot.docs.map((doc) => CombatResult.fromJson(doc.data())).toList();
    });
  }
  // --- NOUVELLE MÉTHODE POUR SAUVEGARDER LES DONNÉES DU LABORATOIRE DE RECHERCHE ---
  Future<void> saveResearchData({required String userId, required LaboratoireRecherche research}) async {
    try {
      await _db.collection('users').doc(userId).update({
        'research': research.toJson(), // Stocke les données de recherche sous un sous-champ 'research'
      });
      print("Données de recherche sauvegardées pour l'utilisateur: $userId");
    } catch (e) {
      print("Erreur lors de la sauvegarde des données de recherche: $e");
      rethrow; // Propage l'erreur pour qu'elle puisse être gérée plus haut
    }
  }
}