import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/hive_service.dart'; // Importe HiveService
import '../services/firestore_service.dart'; // Importe FirestoreService
import '../models/ressources_defensives.dart'; // Importe les modèles dont on aura besoin
import '../models/laboratoire_recherche.dart';
import '../models/memoire_immunitaire.dart';
import '../models/base_virale.dart'; // Peut être utile pour allViralBasesProvider


// --- Providers liés à l'authentification ---

// Un Provider qui fournit une instance de notre AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Un StreamProvider qui écoute l'état de l'utilisateur connecté depuis AuthService
// Il émet null si l'utilisateur est déconnecté, ou un objet User si connecté
// ref.watch(this) émettra un AsyncValue<User?>
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.user; // C'est le Stream réel
});


// --- Provider pour HiveService ---
final hiveServiceProvider = Provider<HiveService>((ref) {
  // S'assurer que Hive est initialisé avant d'obtenir le service (fait dans main.dart)
  // assert(Hive.isBoxOpen('resourcesBox')); // Optional: ajoute une vérification au démarrage
  return HiveService();
});


// --- Providers liés à Firestore ---

// Un Provider qui fournit une instance de notre FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});


// Un StreamProvider qui gère la synchronisation du profil utilisateur entre Hive et Firestore.
// Il dépend de authStateChangesProvider (pour l'UID) et écoute le stream de Firestore.
// Ce provider renvoie un Stream<Map<String, dynamic>?>.
final userProfileProvider = StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {

  // Regarde l'état d'authentification (c'est un AsyncValue<User?>)
  final authState = ref.watch(authStateChangesProvider);

  // Utilise .when pour gérer les différents états de l'authentification (loading, data, error)
  // Le corps de 'data' est async* pour pouvoir émettre des valeurs sur un stream
  return authState.when(
    // Quand l'état d'authentification a des données (l'AsyncValue contient un User? ou null)
    data: (user) async* { // <-- Corps async* ici
      // Si un utilisateur est connecté (le User n'est pas null)
      if (user != null) {
        final userId = user.uid;
        final hiveService = ref.watch(hiveServiceProvider); // Obtient HiveService
        final firestoreService = ref.watch(firestoreServiceProvider); // Obtient FirestoreService


        // 1. Tente de lire les données depuis Hive D'ABORD (lecture synchrone)
        final localResources = hiveService.getResources(userId);
        final localResearch = hiveService.getResearch(userId);
        final localImmuneMemory = hiveService.getImmuneMemory(userId);

        // Crée une Map à partir des données locales si elles existent et émet-la
        Map<String, dynamic>? localProfileData;
        if (localResources != null && localResearch != null && localImmuneMemory != null) {
          print('UserProfileProvider: Profil utilisateur chargé depuis Hive pour $userId');
          localProfileData = {
            'resources': localResources.toJson(),
            'research': localResearch.toJson(),
            'immuneMemory': localImmuneMemory.toJson(),
            'email': user.email, // Ajoute l'email qui vient de l'auth
          };
          yield localProfileData; // Émet la donnée locale immédiatement
        } else {
          print('UserProfileProvider: Profil utilisateur non trouvé ou incomplet dans Hive pour $userId. Attente de Firestore...');
          yield null; // Émet null si pas de données locales complètes, en attendant Firestore
        }


        // 2. Écoute MAINTENANT le Stream Firestore
        print('UserProfileProvider: Début de l\'écoute du Stream Firestore pour le profil utilisateur $userId');
        // streamUserProfile retourne un Stream<Map<String, dynamic>?>
        // Boucle sur les valeurs émises par le stream Firestore
        await for (final firestoreData in firestoreService.streamUserProfile(userId)) {
          if (firestoreData != null) {
            print('UserProfileProvider: Données Firestore reçues pour $userId. Sauvegarde dans Hive et émission.');
            // Sauvegarde les données reçues de Firestore dans Hive.
            // await ici est nécessaire car les méthodes save sont Future<void>.
            if (firestoreData.containsKey('resources')) {
              final resources = RessourcesDefensives.fromJson(Map<String, dynamic>.from(firestoreData['resources']));
              await hiveService.saveResources(userId, resources); // <-- Ajout de await
            }
            if (firestoreData.containsKey('research')) {
              final research = LaboratoireRecherche.fromJson(Map<String, dynamic>.from(firestoreData['research']));
              await hiveService.saveResearch(userId, research); // <-- Ajout de await
            }
            if (firestoreData.containsKey('immuneMemory')) {
              final immuneMemory = MemoireImmunitaire.fromJson(Map<String, dynamic>.from(firestoreData['immuneMemory']));
              await hiveService.saveImmuneMemory(userId, immuneMemory); // <-- Ajout de await
            }
            // TODO: Sauvegarder d'autres parties du profil si nécessaire

            // Émet les données reçues de Firestore (après la sauvegarde dans Hive)
            yield firestoreData;

          } else {
            // Si Firestore émet null (document supprimé ?), on nettoie Hive et on émet null
            print('UserProfileProvider: Firestore émet null pour $userId. Nettoyage Hive.');
            await hiveService.deleteUserData(userId); // Nettoie les données locales pour cet utilisateur. await est nécessaire.
            yield null; // Émet null
          }
        } // Fin du await for (boucle sur le stream Firestore)

      } else {
        // Si aucun utilisateur n'est connecté (user est null)
        print('UserProfileProvider: Aucun utilisateur connecté, émet null.');
        yield null; // Émet null car pas d'utilisateur connecté
      }
    },
    // Pendant le chargement de l'état d'authentification
    loading: () => Stream.value(null), // Émet un stream qui contient juste null pendant le chargement initial de l'auth
    // En cas d'erreur de l'état d'authentification
    error: (err, stack) => Stream.error(err), // Émet un stream d'erreur
  );
});


// Provider pour les Ressources de l'utilisateur (dépend de userProfileProvider)
// Ce provider regarde userProfileProvider (qui émet Map<String, dynamic>?)
// et en extrait l'objet RessourcesDefensives?.
// Il utilise .when sur l'AsyncValue de userProfileProvider pour réagir aux états (loading, data, error).
final userResourcesProvider = Provider.autoDispose<RessourcesDefensives?>((ref) {
  final userProfileAsyncValue = ref.watch(userProfileProvider); // Regarde l'AsyncValue du profil

  // Utilise .when pour gérer l'état de l'AsyncValue du profil utilisateur
  return userProfileAsyncValue.when(
    // Si le profil est chargé (AsyncValue a des data)
    data: (profileData) {
      // Si les données du profil existent et contiennent le champ 'resources'
      if (profileData != null && profileData.containsKey('resources')) {
        // Convertit la Map 'resources' en objet RessourcesDefensives
        return RessourcesDefensives.fromJson(Map<String, dynamic>.from(profileData['resources']));
      }
      // Si le profilData est null ou ne contient pas 'resources', retourne null
      return null;
    },
    // Pendant le chargement du profil
    loading: () => null, // Émet null pendant le chargement
    // En cas d'erreur du profil
    error: (err, stack) => null, // Émet null en cas d'erreur (tu pourrais émettre une erreur spécifique si tu voulais)
  );
});

// Provider pour le Laboratoire de Recherche de l'utilisateur (dépend de userProfileProvider)
final userResearchProvider = Provider.autoDispose<LaboratoireRecherche?>((ref) {
  final userProfileAsyncValue = ref.watch(userProfileProvider);
  return userProfileAsyncValue.when(
    data: (profileData) {
      if (profileData != null && profileData.containsKey('research')) {
        return LaboratoireRecherche.fromJson(Map<String, dynamic>.from(profileData['research']));
      }
      return null;
    },
    loading: () => null,
    error: (err, stack) => null,
  );
});

// Provider pour la Mémoire Immunitaire de l'utilisateur (dépend de userProfileProvider)
final userImmuneMemoryProvider = Provider.autoDispose<MemoireImmunitaire?>((ref) {
  final userProfileAsyncValue = ref.watch(userProfileProvider);
  return userProfileAsyncValue.when(
    data: (profileData) {
      if (profileData != null && profileData.containsKey('immuneMemory')) {
        return MemoireImmunitaire.fromJson(Map<String, dynamic>.from(profileData['immuneMemory']));
      }
      return null;
    },
    loading: () => null,
    error: (err, stack) => null,
  );
});


// Un StreamProvider qui écoute la liste de toutes les bases virales dans Firestore (pour le scanner)
// Ce provider renvoie un Stream<List<BaseVirale>>.
final allViralBasesProvider = StreamProvider.autoDispose<List<BaseVirale>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider); // Obtient FirestoreService
  return firestoreService.streamAllViralBases(); // Retourne le Stream réel depuis le service Firestore
});

// Note sur .autoDispose : c'est une bonne pratique pour les providers qui ne sont pas toujours nécessaires.
// Riverpod les supprime automatiquement quand ils ne sont plus écoutés, libérant des ressources.