// lib/services/gemini_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Pour lire la clé API

// Définition du provider pour GeminiService
final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

class GeminiService {
  late final GenerativeModel _model; // Le modèle Gemini que nous allons utiliser

  GeminiService() {
    // Tente de récupérer la clé API depuis le fichier .env
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      // Si la clé n'est pas trouvée, lance une erreur pour avertir
      throw Exception('GEMINI_API_KEY non trouvée dans le fichier .env. Assurez-vous qu\'il existe et qu\'il est chargé.');
    }
    // Initialisation du modèle Gemini Pro
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey); // CHANGÉ DE 'gemini-1.5-flash' à 'gemini-pro'
  }

  /// Envoie un prompt (question ou instruction) à l'API Gemini et retourne sa réponse textuelle.
  Future<String> getGeminiResponse(String prompt) async {
    try {
      // Instructions système pour définir le rôle et le contexte du jeu ImmunoWarriors
      final systemInstruction = Content.text(
          "Vous êtes le Conseiller Médical IA du jeu ImmunoWarriors. "
              "Votre rôle est d'aider le joueur à comprendre les mécanismes de défense immunitaire, "
              "les virus, les bactéries, les ressources du jeu (énergie cellulaire, substances vitales, points d'analyse), "
              "les bâtiments (Pharmacie Synthétique, Laboratoire R&D, Scanner, Dossiers Patients), "
              "et les stratégies de combat. Répondez de manière informative et pertinente au contexte du jeu ImmunoWarriors. "
              "Le jeu est basé sur la gestion d'une base immunitaire pour combattre des pathogènes."
      );

      // Crée le contenu à envoyer à Gemini, incluant les instructions système en premier
      final content = [
        systemInstruction, // Les instructions système sont envoyées en premier
        Content.text(prompt) // Le message de l'utilisateur est ensuite envoyé
      ];

      // Envoie le contenu au modèle et attend la réponse
      final response = await _model.generateContent(content);

      // Vérifie si la réponse contient du texte
      if (response.text != null) {
        return response.text!; // Retourne le texte de la réponse
      } else {
        // Si la réponse n'a pas de texte (peut arriver si le modèle est bloqué ou autre)
        return "Je n'ai pas pu générer de réponse pour le moment. Veuillez reformuler votre question.";
      }
    } catch (e) {
      // Capture toute erreur survenant pendant l'appel API (réseau, authentification, etc.)
      print('Erreur lors de l\'appel à Gemini API: $e');
      return "Une erreur est survenue lors de la communication avec l'IA. Veuillez vérifier votre connexion ou réessayer plus tard.";
    }
  }

// *******************************************************************
// Optionnel : Méthode pour un chat plus continu (si vous voulez garder l'historique)
// Nous ne l'utiliserons pas tout de suite pour simplifier, mais c'est pour référence.
// late final ChatSession _chat; // Déclare une session de chat
//
// // Méthode pour démarrer une nouvelle session de chat
// void startNewChatSession() {
//   _chat = _model.startChat(history: []); // Commence un chat vide
// }
//
// // Méthode pour envoyer un message dans le chat et obtenir la réponse
// Future<String> getChatResponse(String message) async {
//   try {
//     final response = await _chat.sendMessage(Content.text(message));
//     return response.text ?? "Je n'ai pas pu répondre.";
//   } catch (e) {
//     print('Erreur lors de la session de chat Gemini: $e');
//     return "Erreur dans la conversation. Veuillez relancer la discussion.";
//   }
// }
// *******************************************************************
}