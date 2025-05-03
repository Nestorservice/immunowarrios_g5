import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/auth_state_provider.dart'; // Importe notre StreamProvider (qui contient maintenant tous les providers)
import 'login_page.dart';
import 'dashboard_page.dart';

// Ce widget écoute l'état d'authentification et affiche la bonne page
class AuthChecker extends ConsumerWidget { // On utilise ConsumerWidget pour pouvoir écouter les providers
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // build prend maintenant un WidgetRef
    // On 'watch' (regarde/écoute) le authStateChangesProvider
    // Quand l'état de l'utilisateur change (connexion/déconnexion),
    // ce widget se reconstruit avec la nouvelle valeur (user)
    // Utilise .when pour gérer l'état du StreamProvider d'authentification:
    // data: quand le Stream a émis une donnée (soit un User, soit null)
    // error: si le Stream a eu une erreur
    // loading: tant que le Stream n'a pas encore émis sa première donnée
    return ref.watch(authStateChangesProvider).when(
      data: (user) {
        // Si user n'est PAS null, l'utilisateur est connecté
        if (user != null) {
          print("Utilisateur connecté: ${user.uid}"); // Pour vérifier dans la console
          // On affiche la page du Tableau de Bord (la page principale)
          return const DashboardPage();
        } else {
          print("Utilisateur déconnecté."); // Pour vérifier dans la console
          // Si user est null, l'utilisateur n'est PAS connecté
          // On affiche la page de Connexion/Enregistrement
          return const LoginPage();
        }
      },
      // Pendant que le stream charge (peut arriver brièvement au démarrage)
      loading: () => const Scaffold( // On affiche un indicateur de chargement simple
        body: Center(child: CircularProgressIndicator()),
      ),
      // En cas d'erreur du stream (rare pour authStateChanges)
      error: (err, stack) => Scaffold( // On affiche un message d'erreur
        body: Center(child: Text('Erreur de chargement auth: $err')),
      ),
    );
  }
}