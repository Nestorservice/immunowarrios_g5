import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart'; // Importe notre AuthService

// Un Provider qui fournit une instance de notre AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Un StreamProvider qui écoute l'état de l'utilisateur connecté depuis AuthService
// Il émet null si l'utilisateur est déconnecté, ou un objet User si connecté
final authStateChangesProvider = StreamProvider<User?>((ref) {
  // On 'watch' (écoute) le authServiceProvider pour obtenir l'instance de AuthService
  final authService = ref.watch(authServiceProvider);
  // On retourne le stream d'état de l'utilisateur
  return authService.user;
});