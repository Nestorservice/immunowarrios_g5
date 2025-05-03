import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/auth_state_provider.dart'; // Importe notre AuthService Provider et l'état de l'utilisateur

class DashboardPage extends ConsumerWidget { // Utilise ConsumerWidget
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On obtient l'instance de AuthService pour la déconnexion
    final authService = ref.watch(authServiceProvider);
    // On obtient l'utilisateur connecté pour afficher son email
    final user = ref.watch(authStateChangesProvider).value; // Le .value est important ici

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de Bord Immunitaire')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Affiche l'email de l'utilisateur connecté si disponible
            Text('Bienvenue Cyber-Guerrier !'),
            if (user != null && user.email != null) // Vérifie que user et son email ne sont pas null
              Text('Connecté en tant que : ${user.email!}'), // user.email! car on a vérifié qu'il n'est pas null
            const SizedBox(height: 20),

            // Bouton de Déconnexion
            ElevatedButton(
              onPressed: () async {
                // Appelle la méthode de déconnexion de notre AuthService
                await authService.signOut();
                // AuthChecker va détecter la déconnexion et naviguer automatiquement
              },
              child: const Text('Déconnexion'),
            ),
            // On ajoutera ici les boutons vers les autres sections (Scanner, Bio-Forge, etc.) plus tard
          ],
        ),
      ),
    );
  }
}