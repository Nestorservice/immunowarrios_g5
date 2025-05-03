import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // On importe Material pour les messages (SnackBar)

// Une classe pour gérer toutes les opérations d'authentification
class AuthService {
  // On obtient une instance de FirebaseAuth (le cœur du service Auth)
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Méthode pour enregistrer un nouvel utilisateur avec email et mot de passe
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      // On utilise la méthode de Firebase pour créer un utilisateur
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Si ça réussit, Firebase renvoie un objet UserCredential, on retourne l'utilisateur (User)
      return credential.user;
    } on FirebaseAuthException catch (e) {
      // Si une erreur Firebase spécifique se produit (ex: email déjà utilisé, mot de passe trop faible)
      if (e.code == 'weak-password') {
        print('Le mot de passe est trop faible.');
        // On pourrait montrer un message à l'utilisateur ici, par exemple avec un SnackBar
        // ScaffoldMessenger.of(context).showSnackBar(...)
      } else if (e.code == 'email-already-in-use') {
        print('Cette adresse email est déjà utilisée.');
      } else {
        print('Erreur d\'enregistrement : ${e.message}');
      }
      // En cas d'erreur, on retourne null
      return null;
    } catch (e) {
      // Gérer les autres types d'erreurs
      print('Une erreur inattendue s\'est produite lors de l\'enregistrement: $e');
      return null;
    }
  }

  // Méthode pour connecter un utilisateur existant avec email et mot de passe
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // On utilise la méthode de Firebase pour connecter un utilisateur
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Si ça réussit, on retourne l'utilisateur
      return credential.user;
    } on FirebaseAuthException catch (e) {
      // Gérer les erreurs de connexion (ex: utilisateur non trouvé, mauvais mot de passe)
      if (e.code == 'user-not-found') {
        print('Aucun utilisateur trouvé pour cette adresse email.');
      } else if (e.code == 'wrong-password') {
        print('Mot de passe incorrect.');
      } else {
        print('Erreur de connexion : ${e.code}');
      }
      // En cas d'erreur, on retourne null
      return null;
    } catch (e) {
      print('Une erreur inattendue s\'est produite lors de la connexion: $e');
      return null;
    }
  }

  // Méthode pour déconnecter l'utilisateur actuel
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('Déconnexion réussie.');
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    }
  }

  // Méthode pour obtenir l'utilisateur actuellement connecté (null si personne n'est connecté)
  // Ceci est un Stream, il va émettre une nouvelle valeur à chaque changement d'état (connexion/déconnexion)
  Stream<User?> get user {
    return _auth.authStateChanges();
  }
}