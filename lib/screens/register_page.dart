import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/auth_state_provider.dart';

// --- Réutilise la même palette de couleurs pour la cohérence ---
const Color primaryColor = Color(0xFF4CAF50); // Vert immunitaire
const Color accentColor = Color(0xFF2196F3); // Bleu technologique
const Color cardColor = Color(0xFFFFFFFF); // Fond blanc pour la carte du formulaire
const Color textColor = Color(0xFF333333); // Texte sombre
const Color subTextColor = Color(0xFF555555); // Texte moins important
const Color successColor = Color(0xFF4CAF50); // Vert pour les messages de succès
const Color errorColor = Colors.redAccent; // Couleur pour les messages d'erreur

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Controllers pour les champs email et mot de passe
    // REMARQUE : Voir la note sur les TextEditingController dans LoginPage pour une gestion propre
    // de la mémoire dans un projet réel (utiliser StatefulWidget et dispose()).
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    // On obtient l'instance de AuthService via le provider
    final authService = ref.watch(authServiceProvider);

    return Scaffold(
      // Amélioration de l'AppBar
      appBar: AppBar(
        title: const Text('Créer un Cyber-Profil', style: TextStyle(color: Colors.white)), // Titre blanc
        backgroundColor: primaryColor, // Couleur de fond verte
        elevation: 4.0, // Ombre légère
        centerTitle: true, // Centrer le titre
      ),
      body: Container(
        // Optionnel : Ajouter un dégradé ou une image de fond subtile (commenté)
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     begin: Alignment.topCenter,
        //     end: Alignment.bottomCenter,
        //     colors: [Colors.lightGreen[100]!, Colors.lightBlue[100]!],
        //   ),
        // ),
        child: Center(
          child: SingleChildScrollView(
            // Ajout de padding autour du contenu scrollable
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Étirer les éléments
              children: [
                // --- Titre de la Page ---
                Text(
                  'Rejoins la Cyber-Défense',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28, // Plus grande taille
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    // Utiliser GoogleFonts si importé: GoogleFonts.orbitron(fontSize: 28, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(height: 30),

                // --- Formulaire dans un Card ---
                Card(
                  elevation: 8.0, // Ombre plus prononcée
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Coins arrondis
                  child: Padding(
                    padding: const EdgeInsets.all(20.0), // Padding à l'intérieur de la carte
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Champ pour l'email (Stylisé)
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Cyber-Profil',
                            labelStyle: TextStyle(color: subTextColor),
                            prefixIcon: Icon(Icons.email_outlined, color: accentColor), // Icône email
                            border: OutlineInputBorder( // Bordure stylisée
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: accentColor, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder( // Bordure quand le champ est focus
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: primaryColor, width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder( // Bordure quand le champ n'est pas focus
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: accentColor.withOpacity(0.5), width: 1.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: textColor),
                          cursorColor: primaryColor,
                        ),
                        const SizedBox(height: 20), // Espace entre les champs

                        // Champ pour le mot de passe (Stylisé)
                        TextField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Mot de Passe d\'Accès',
                            labelStyle: TextStyle(color: subTextColor),
                            prefixIcon: Icon(Icons.lock_outline, color: accentColor), // Icône cadenas
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: accentColor, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: primaryColor, width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: accentColor.withOpacity(0.5), width: 1.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                          ),
                          obscureText: true,
                          style: TextStyle(color: textColor),
                          cursorColor: primaryColor,
                        ),
                        const SizedBox(height: 30), // Espace avant les boutons

                        // Bouton d'Enregistrement (Stylisé)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor, // Couleur de fond verte
                            foregroundColor: Colors.white, // Texte blanc
                            padding: const EdgeInsets.symmetric(vertical: 15.0), // Padding vertical
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Coins arrondis
                            elevation: 5.0, // Ombre
                          ),
                          onPressed: () async {
                            final email = emailController.text.trim();
                            final password = passwordController.text.trim();

                            if (email.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Veuillez remplir tous les champs.'),
                                  backgroundColor: errorColor, // Fond rouge pour erreur
                                ),
                              );
                              return;
                            }

                            final currentContext = context;
                            final currentUserRef = ref;

                            // Optionnel : Afficher un indicateur de chargement
                            // showDialog(...);

                            try {
                              User? user = await authService.signUpWithEmailAndPassword(email, password);

                              // Fermer l'indicateur de chargement si utilisé
                              // Navigator.of(currentContext).pop();

                              if (!currentUserRef.context.mounted) {
                                return;
                              }

                              if (user != null) {
                                ScaffoldMessenger.of(currentContext).showSnackBar(
                                  SnackBar(
                                    content: const Text('Cyber-Profil créé avec succès !'),
                                    backgroundColor: successColor, // Fond vert pour succès
                                  ),
                                );
                                // Revenir à la page de connexion après un court délai (optionnel)
                                await Future.delayed(const Duration(seconds: 2)); // Ajoute un petit délai
                                if (currentUserRef.context.mounted) {
                                  Navigator.pop(currentContext);
                                }

                              } else {
                                // Si l'enregistrement échoue (l'erreur spécifique est gérée dans AuthService)
                                // Un message d'erreur générique est affiché.
                                ScaffoldMessenger.of(currentContext).showSnackBar(
                                  SnackBar(
                                    content: const Text('Échec de la création du Cyber-Profil. Email déjà utilisé ou mot de passe faible ?'),
                                    backgroundColor: errorColor, // Fond rouge pour erreur
                                  ),
                                );
                              }
                            } catch (e) {
                              // Gestion des erreurs potentielles non gérées par AuthService de base
                              // Fermer l'indicateur de chargement si utilisé
                              // Navigator.of(currentContext).pop();

                              if (!currentUserRef.context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(currentContext).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur lors de la création : ${e.toString()}'),
                                  backgroundColor: errorColor,
                                ),
                              );
                              print('Erreur d\'enregistrement : $e'); // Log pour le debug
                            }

                          },
                          child: const Text(
                            'Créer mon Cyber-Profil',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Texte plus grand et gras
                          ),
                        ),
                        const SizedBox(height: 15), // Espace entre les boutons
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20), // Espace après la carte

                // Bouton pour revenir à la page de connexion (Stylisé)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: accentColor, // Couleur bleue pour le texte
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Déjà membre ? Connexion",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}