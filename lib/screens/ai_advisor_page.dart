// lib/screens/ai_advisor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/gemini_service.dart'; // Importe notre service Gemini
import '../models/combat_result.dart'; // Pour utiliser Timestamp si nécessaire (non directement utilisé ici, mais bonne pratique si on voulait lier à l'historique)

// --- Couleurs thématiques (définies ici pour ne pas dépendre de dashboard_page.dart) ---
const Color hospitalPrimaryGreen = Color(0xFF4CAF50);
const Color hospitalAccentPink = Color(0xFFE91E63);
const Color hospitalBackgroundColor = Color(0xFFF5F5F5);
const Color hospitalCardColor = Color(0xFFFFFFFF);
const Color hospitalTextColor = Color(0xFF212121);
const Color hospitalSubTextColor = Color(0xFF757575);
const Color hospitalWarningColor = Color(0xFFFF9800);
const Color hospitalErrorColor = Color(0xFFF44336);


// Un provider pour gérer l'état des messages de la conversation
// Il contiendra une liste de paires (bool isUser, String message)
// où isUser est true si c'est un message de l'utilisateur, false si c'est de l'IA.
final conversationProvider = StateNotifierProvider<ConversationNotifier, List<Map<String, dynamic>>>((ref) {
  return ConversationNotifier();
});

class ConversationNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  ConversationNotifier() : super([]);

  void addMessage(String message, {required bool isUser}) {
    state = [...state, {'text': message, 'isUser': isUser}];
  }

  void clearConversation() {
    state = [];
  }
}


class AiAdvisorPage extends ConsumerStatefulWidget {
  const AiAdvisorPage({super.key});

  @override
  ConsumerState<AiAdvisorPage> createState() => _AiAdvisorPageState();
}

class _AiAdvisorPageState extends ConsumerState<AiAdvisorPage> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Fonction pour envoyer la question à Gemini
  Future<void> _sendQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez poser une question !')),
      );
      return;
    }

    // Ajoute la question de l'utilisateur à la conversation
    ref.read(conversationProvider.notifier).addMessage(question, isUser: true);
    _questionController.clear(); // Efface le champ de texte

    setState(() {
      _isLoading = true; // Active l'indicateur de chargement
    });

    // Fait défiler jusqu'en bas pour voir le nouveau message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    try {
      final geminiService = ref.read(geminiServiceProvider);
      // Appelle le service Gemini pour obtenir une réponse
      final aiResponse = await geminiService.getGeminiResponse(question);

      // Ajoute la réponse de l'IA à la conversation
      ref.read(conversationProvider.notifier).addMessage(aiResponse, isUser: false);
    } catch (e) {
      ref.read(conversationProvider.notifier).addMessage(
        "Désolé, une erreur est survenue lors de la récupération de la réponse: $e",
        isUser: false,
      );
    } finally {
      setState(() {
        _isLoading = false; // Désactive l'indicateur de chargement
      });
      // Fait défiler à nouveau après la réponse de l'IA
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(conversationProvider); // Écoute la conversation

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Conseiller Médical IA',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: hospitalPrimaryGreen,
        elevation: 1.0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nouvelle conversation',
            onPressed: () {
              ref.read(conversationProvider.notifier).clearConversation();
            },
          ),
        ],
      ),
      backgroundColor: hospitalBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: conversation.length,
              itemBuilder: (context, index) {
                final message = conversation[index];
                final bool isUser = message['isUser'];
                final String text = message['text'];

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isUser ? hospitalPrimaryGreen.withOpacity(0.8) : hospitalCardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isUser ? 15 : 0),
                        topRight: Radius.circular(isUser ? 0 : 15),
                        bottomLeft: const Radius.circular(15),
                        bottomRight: const Radius.circular(15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      text,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: isUser ? Colors.white : hospitalTextColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) // Affiche l'indicateur de chargement si une réponse est en attente
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: hospitalPrimaryGreen),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'Posez une question à l\'IA...',
                      hintStyle: GoogleFonts.roboto(color: hospitalSubTextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: hospitalCardColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                    ),
                    style: GoogleFonts.roboto(color: hospitalTextColor),
                    onSubmitted: (_) => _sendQuestion(), // Permet d'envoyer en appuyant sur Entrée
                  ),
                ),
                const SizedBox(width: 8.0),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendQuestion, // Désactive le bouton pendant le chargement
                  backgroundColor: hospitalPrimaryGreen,
                  mini: true,
                  child: Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}