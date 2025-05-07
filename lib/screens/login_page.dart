import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/auth_state_provider.dart';
import 'register_page.dart';

// --- Réutilise la même palette de couleurs pour la cohérence ---
const Color primaryColor = Color(0xFF4CAF50); // Vert immunitaire
const Color accentColor = Color(0xFF2196F3); // Bleu technologique
const Color cardColor = Color(0xFFFFFFFF); // Fond blanc pour la carte du formulaire
const Color textColor = Color(0xFF333333); // Texte sombre
const Color subTextColor = Color(0xFF555555); // Texte moins important
const Color errorColor = Colors.redAccent; // Couleur pour les messages d'erreur

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On crée des TextEditingController pour récupérer le texte des champs
    // REMARQUE : Comme mentionné dans ton code original, pour une gestion propre
    // de la mémoire, il faudrait utiliser un StatefulWidget ou un package comme flutter_hooks.
    // Pour les besoins du style ici, on garde la structure simple.
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    // On obtient l'instance de AuthService via le provider
    final authService = ref.watch(authServiceProvider);

    // IMPORTANT: Pense à disposer des controllers quand le widget n'est plus utilisé
    // dans un vrai projet (typiquement dans dispose() d'un StatefulWidget).

    return Scaffold(
      // Amélioration de l'AppBar
      appBar: AppBar(
        title: const Text('Connexion Sécurisée', style: TextStyle(color: Colors.white)), // Titre blanc
        backgroundColor: primaryColor, // Couleur de fond verte
        elevation: 4.0, // Ombre légère
        centerTitle: true, // Centrer le titre
      ),
      body: Container(
        // Optionnel : Ajouter un dégradé ou une image de fond subtile au body
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     begin: Alignment.topCenter,
        //     end: Alignment.bottomCenter,
        //     colors: [Colors.lightGreen[100]!, Colors.lightBlue[100]!], // Exemple de dégradé doux
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
                  'Accès Cyber-Immunitaire',
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
                  elevation: 8.0, // Ombre plus prononcée pour le formulaire
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
                          style: TextStyle(color: textColor), // Couleur du texte entré
                          cursorColor: primaryColor, // Couleur du curseur
                        ),
                        const SizedBox(height: 20), // Plus d'espace entre les champs

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
                        const SizedBox(height: 30), // Plus d'espace avant les boutons

                        // Bouton de Connexion (Stylisé)
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

                            // Afficher un indicateur de chargement si souhaité (optionnel)
                            // showDialog(...); // Ouvre une boîte de dialogue de chargement

                            User? user = await authService.signInWithEmailAndPassword(email, password);

                            // Fermer l'indicateur de chargement si utilisé
                            // Navigator.of(currentContext).pop();

                            if (!currentUserRef.context.mounted) {
                              return;
                            }

                            if (user == null) {
                              ScaffoldMessenger.of(currentContext).showSnackBar(
                                SnackBar(
                                  content: const Text('Échec de la connexion. Vérifie email et mot de passe.'),
                                  backgroundColor: errorColor, // Fond rouge pour erreur
                                ),
                              );
                            }
                            // La navigation réussie est gérée par AuthChecker.
                          },
                          child: const Text(
                            'Accéder à la Cyber-Défense',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Texte plus grand et gras
                          ),
                        ),
                        const SizedBox(height: 15), // Espace entre les boutons
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20), // Espace après la carte

                // Bouton pour aller vers la page d'enregistrement (Stylisé)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: accentColor, // Couleur bleue pour le texte
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  child: const Text(
                    "Pas encore de compte ? Crée un Cyber-Profil",
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