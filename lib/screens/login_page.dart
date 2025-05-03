import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immuno_warriors/screens/register_page.dart';
import '../state/auth_state_provider.dart'; // Importe notre AuthService Provider

class LoginPage extends ConsumerWidget { // Utilise ConsumerWidget pour accéder au provider AuthService
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On crée des TextEditingController pour récupérer le texte des champs
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    // On obtient l'instance de AuthService via le provider
    final authService = ref.watch(authServiceProvider);

    // Important: Nettoyer les controllers quand le widget n'est plus utilisé
    // Bien que ce soit un StatelessWidget, les controllers doivent être disposed
    // Pour un StatelessWidget, on devrait utiliser un StatefulWidget ou un package comme flutter_hooks
    // Pour l'exemple simple, on va juste les créer ici. Dans un vrai projet, utiliser StatefulWidget + dispose()
    // Ou mieux, utiliser un StateNotifierProvider pour gérer l'état du formulaire et des controllers
    // Mais pour démarrer simple, on fait comme ça.

    return Scaffold(
      appBar: AppBar(title: const Text('Connexion Cyber-Immunitaire')),
      body: Center(
        // Utilise SingleChildScrollView pour éviter les problèmes de clavier qui cache les champs
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Champ pour l'email
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12), // Un petit espace

              // Champ pour le mot de passe
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true, // Pour cacher le mot de passe
              ),
              const SizedBox(height: 20),

              // Bouton de Connexion
              ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();

                  // Vérifie si les champs ne sont pas vides
                  if (email.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez remplir tous les champs.')),
                    );
                    return;
                  }

                  // Capture le contexte et la référence Riverpod AVANT l'opération asynchrone
                  final currentContext = context;
                  final currentUserRef = ref;

                  // Appelle la méthode de connexion de notre AuthService
                  User? user = await authService.signInWithEmailAndPassword(email, password);

                  // **AJOUT IMPORTANT :** Vérifie si le widget est toujours monté avant de continuer
                  if (!currentUserRef.context.mounted) {
                    return;
                  }

                  if (user == null) {
                    // Si la connexion échoue (l'erreur spécifique est gérée dans AuthService et imprimée dans la console)
                    // On affiche un message générique à l'utilisateur via SnackBar
                    ScaffoldMessenger.of(currentContext).showSnackBar( // Utilise le context capturé
                      const SnackBar(content: Text('Échec de la connexion. Vérifie email et mot de passe.')),
                    );
                  }
                  // Si la connexion réussit, AuthChecker va détecter le changement d'état
                  // (authService.user va émettre un User non null) et naviguer automatiquement vers le Dashboard.
                  // On n'a rien d'autre à faire ici après un succès.
                },
                child: const Text('Connexion'),
              ),
              const SizedBox(height: 8),

              // Bouton pour aller vers la page d'enregistrement
              TextButton(
                onPressed: () {
                  // Navigue vers la page d'enregistrement
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage()), // On créera cette page juste après
                  );
                },
                child: const Text("Pas encore de compte ? Crée un Cyber-Profil"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}