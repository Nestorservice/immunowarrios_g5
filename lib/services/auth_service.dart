import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firestore_service.dart'; // <-- Importe FirestoreService

// Une classe pour gérer toutes les opérations d'authentification
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService(); // <-- Instance de FirestoreService

  // Méthode pour enregistrer un nouvel utilisateur avec email et mot de passe
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = credential.user;

      if (user != null) {
        // **AJOUT IMPORTANT :** Créer le profil utilisateur dans Firestore
        await _firestoreService.createUserProfile(
          userId: user.uid, // Utilise l'UID de l'utilisateur créé
          email: user.email ?? '', // Utilise l'email de l'utilisateur
          // Passe d'autres données initiales si nécessaire
        );
        print('Profil Firestore créé pour l\'utilisateur ${user.uid}');
      }

      return user; // Retourne l'utilisateur (sera null si une exception est levée)

    } on FirebaseAuthException catch (e) {
      // ... (ton code de gestion des erreurs existant) ...
      if (e.code == 'weak-password') {
        print('Le mot de passe est trop faible.');
      } else if (e.code == 'email-already-in-use') {
        print('Cette adresse email est déjà utilisée.');
      } else {
        print('Erreur d\'enregistrement : ${e.message}');
      }
      return null;
    } catch (e) {
      print('Une erreur inattendue s\'est produite lors de l\'enregistrement: $e');
      return null;
    }
  }

  // ... (Le reste de ta classe AuthService, signInWithEmailAndPassword, signOut, user) ...

  // Méthode pour connecter un utilisateur existant avec email et mot de passe
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Pas besoin de créer un profil ici, il existe déjà
      return credential.user;
    } on FirebaseAuthException catch (e) {
      // ... (ton code de gestion des erreurs existant) ...
      if (e.code == 'user-not-found') {
        print('Aucun utilisateur trouvé pour cette adresse email.');
      } else if (e.code == 'wrong-password') {
        print('Mot de passe incorrect.');
      } else {
        print('Erreur de connexion : ${e.code}');
      }
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
  Stream<User?> get user {
    return _auth.authStateChanges();
  }
}