import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/auth_state_provider.dart'; // Importe notre AuthService Provider

class RegisterPage extends ConsumerWidget { // Utilise ConsumerWidget
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Controllers pour les champs email et mot de passe
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    // On obtient l'instance de AuthService via le provider
    final authService = ref.watch(authServiceProvider);

    // Ici aussi, gestion des controllers comme expliqué dans LoginPage

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un Cyber-Profil')),
      body: Center(
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
              const SizedBox(height: 12),

              // Champ pour le mot de passe
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
              ),
              const SizedBox(height: 20),

              // Bouton d'Enregistrement
              ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();

                  // Vérifie si les champs ne sont pas vides
                  if (email.isEmpty || password.isEmpty) {
                    // Utilise le context directement car on n'a pas d'await ici
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez remplir tous les champs.')),
                    );
                    return; // Arrête le processus ici
                  }

                  // Capture le contexte et la référence Riverpod AVANT l'opération asynchrone
                  final currentContext = context;
                  final currentUserRef = ref;

                  // Appelle la méthode d'enregistrement de notre AuthService
                  User? user = await authService.signUpWithEmailAndPassword(email, password);

                  // **AJOUT IMPORTANT :** Vérifie si le widget est toujours monté avant de continuer
                  if (!currentUserRef.context.mounted) {
                    // Si le widget n'est plus monté (par exemple, l'utilisateur a navigué ailleurs entre temps)
                    // on arrête l'exécution ici pour éviter l'erreur.
                    return;
                  }

                  if (user != null) {
                    // Si l'enregistrement réussit
                    ScaffoldMessenger.of(currentContext).showSnackBar( // Utilise le context capturé
                      const SnackBar(content: Text('Cyber-Profil créé avec succès !')),
                    );
                    // Revenir à la page de connexion
                    // Vérifie à nouveau si le widget est monté avant de naviguer,
                    // bien que Navigator.pop soit généralement sûr APRÈS la SnackBar si le mounted est vérifié avant
                    if (currentUserRef.context.mounted) {
                      Navigator.pop(currentContext); // Utilise le context capturé
                    }
                  } else {
                    // Si l'enregistrement échoue (l'erreur spécifique est gérée dans AuthService et imprimée dans la console)
                    // On affiche un message générique à l'utilisateur via SnackBar
                    ScaffoldMessenger.of(currentContext).showSnackBar( // Utilise le context capturé
                      const SnackBar(content: Text('Échec de la création du Cyber-Profil. Email déjà utilisé ou mot de passe faible ?')),
                    );
                  }
                },
                child: const Text('Créer un Cyber-Profil'),
              ),
              const SizedBox(height: 8),

              // Bouton pour revenir à la page de connexion
              TextButton(
                onPressed: () {
                  // Revenir à la page précédente (LoginPage)
                  Navigator.pop(context);
                },
                child: const Text("Déjà membre ? Connexion"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}