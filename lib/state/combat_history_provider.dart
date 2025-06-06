// lib/state/combat_history_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/combat_result.dart';
import '../services/firestore_service.dart'; // Assurez-vous que firestore_service.dart est importé et contient firestoreServiceProvider
import 'auth_state_provider.dart'; // Pour obtenir l'ID de l'utilisateur

// Provider pour obtenir une instance de FirestoreService
// C'est le bon endroit pour le définir si firestore_service.dart ne l'exporte pas déjà
// ou si vous souhaitez le rendre disponible spécifiquement via ce fichier.
// Si vous l'avez déjà dans firestore_service.dart et que vous l'exportez,
// vous pouvez supprimer cette ligne ici et l'importer directement depuis firestore_service.dart.
// Pour l'instant, je le garde ici pour que ça compile.
final firestoreServiceProvider = Provider((ref) => FirestoreService());


// Provider qui stream la liste des CombatResult pour l'utilisateur actuel
final combatHistoryProvider = StreamProvider.autoDispose<List<CombatResult>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider); // Utilisez le provider correct
  final authState = ref.watch(authStateChangesProvider); // Écoute l'état d'authentification

  // Si l'utilisateur n'est pas connecté, retourne un stream vide.
  // Sinon, stream les résultats de combat pour cet utilisateur.
  return authState.when(
    data: (user) {
      if (user != null) {
        print('CombatHistoryProvider: Streaming l\'historique des combats pour l\'utilisateur: ${user.uid}');
        // Correction ici : Appelle la méthode avec le nom corrigé
        return firestoreService.streamCombatResults(user.uid);
      }
      print('CombatHistoryProvider: Aucun utilisateur connecté, ne streame pas l\'historique des combats.');
      return Stream.value([]);
    },
    loading: () {
      print('CombatHistoryProvider: Authentification en cours, ne streame pas l\'historique des combats.');
      return Stream.value([]);
    },
    error: (err, stack) {
      print('CombatHistoryProvider: Erreur d\'authentification: $err, ne streame pas l\'historique des combats.');
      return Stream.value([]);
    },
  );
});