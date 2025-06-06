import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Importe Google Fonts (ASSURE-TOI D'AVOIR AJOUTÉ LA DÉPENDANCE google_fonts dans pubspec.yaml)
import 'package:google_fonts/google_fonts.dart';

import '../state/auth_state_provider.dart'; // Importe notre StreamProvider
import 'login_page.dart';
import 'dashboard_page.dart';

// --- Palette de couleurs thématique simplifiée pour les états de base ---
// Utilise les couleurs du thème général
const Color accentColor = Color(0xFF00C0F3); // Bleu tech pour l'accent/indicateur
const Color backgroundColor = Color(0xFF1A2B3C); // Fond sombre principal
const Color textColor = Color(0xFFE0E0E0); // Texte clair sur fond sombre
const Color errorColor = Color(0xFFFF6B6B); // Rouge pour erreur


// Ce widget écoute l'état d'authentification et affiche la bonne page
class AuthChecker extends ConsumerWidget { // On utilise ConsumerWidget
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // build prend un WidgetRef
    // On 'watch' (regarde/écoute) le authStateChangesProvider
    // Utilise .when pour gérer l'état du StreamProvider d'authentification:
    return ref.watch(authStateChangesProvider).when(
      // Quand le Stream a émis une donnée (soit un User, soit null)
      data: (user) {
        // Si user n'est PAS null, l'utilisateur est connecté
        if (user != null) {
          print("Utilisateur connecté: ${user.uid}"); // Pour vérifier dans la console
          // On affiche la page du Tableau de Bord stylisée
          return const DashboardPage();
        } else {
          print("Utilisateur déconnecté."); // Pour vérifier dans la console
          // Si user est null, l'utilisateur n'est PAS connecté
          // On affiche la page de Connexion/Enregistrement stylisée
          return const LoginPage();
        }
      },
      // Pendant que le stream charge (peut arriver brièvement au démarrage)
      loading: () => Scaffold( // On affiche un écran de chargement stylisé
        backgroundColor: backgroundColor, // Fond sombre
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: accentColor), // Indicateur stylisé
              const SizedBox(height: 20), // Espace
              Text(
                'Initialisation du Cyber-Système...', // Message de chargement thématique
                style: GoogleFonts.rajdhani( // Police thématique
                  fontSize: 18,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10), // Espace
              Text(
                'Vérification des protocoles d\'authentification...', // Message secondaire
                style: GoogleFonts.lato( // Police standard
                  fontSize: 14,

                ),
              ),
            ],
          ),
        ),
      ),
      // En cas d'erreur du stream (rare pour authStateChanges)
      error: (err, stack) => Scaffold( // On affiche un écran d'erreur stylisé
        backgroundColor: backgroundColor, // Fond sombre
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 50, color: errorColor), // Icône erreur
                const SizedBox(height: 20),
                Text(
                  'Erreur critique du système !', // Titre erreur
                  style: GoogleFonts.orbitron(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: errorColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Impossible de charger l\'état d\'authentification.\nRedémarrez l\'application ou contactez le support.', // Message d'erreur
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Détails: ${err.toString()}', // Détails techniques (moins visibles)
                  style: GoogleFonts.lato(
                    fontSize: 12,

                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}