// lib/screens/combat_history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Pour formater les dates

import '../models/combat_result.dart'; // Importe le modèle CombatResult
// !!! IMPORTANT : Supprimez ces deux imports si vous utilisez un auth_state_provider et firestore_service_provider
// import '../state/auth_state_provider.dart'; // Pour récupérer l'ID utilisateur
// import '../services/firestore_service.dart'; // Pour le service Firestore

// Utilisez le provider défini dans son propre fichier
import '../state/combat_history_provider.dart'; // Importe le provider d'historique de combat
import 'combat_details_page.dart'; // Importe la page de détails de combat

// --- Couleurs thématiques (définies ici pour ne pas dépendre de dashboard_page.dart) ---
const Color hospitalPrimaryGreen = Color(0xFF4CAF50);
const Color hospitalAccentPink = Color(0xFFE91E63);
const Color hospitalBackgroundColor = Color(0xFFF5F5F5);
const Color hospitalCardColor = Color(0xFFFFFFFF);
const Color hospitalTextColor = Color(0xFF212121);
const Color hospitalSubTextColor = Color(0xFF757575);
const Color hospitalWarningColor = Color(0xFFFF9800);
const Color hospitalErrorColor = Color(0xFFF44336);

// Ancien bloc de code à SUPPRIMER :
/*
// Nouveau provider pour l'historique des combats de l'utilisateur actuel
// Ce provider sera utilisé par CombatHistoryPage pour récupérer les données.
final combatHistoryProvider = StreamProvider.autoDispose<List<CombatResult>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final firestoreService = ref.watch(firestoreService); // Utilise l'instance du service Firestore

  return authState.when(
    data: (user) {
      if (user != null) {
        // Appelle la nouvelle méthode streamCombatResults
        return firestoreService.streamCombatResults(user.uid);
      }
      return Stream.value([]); // Retourne une liste vide si pas d'utilisateur
    },
    loading: () => Stream.value([]), // Vide pendant le chargement
    error: (err, stack) => Stream.value([]), // Vide en cas d'erreur
  );
});
*/
// Fin du bloc à SUPPRIMER


class CombatHistoryPage extends ConsumerWidget {
  const CombatHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoute le stream des résultats de combat via le provider
    final combatResultsAsyncValue = ref.watch(combatHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dossiers Patients (Historique des Combats)',
          style: GoogleFonts.poppins(
            color: Colors.white, // Couleur de texte blanche pour la barre
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: hospitalPrimaryGreen, // Fond de la barre en vert
        elevation: 1.0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // Couleur de l'icône de retour
      ),
      body: Container(
        color: hospitalBackgroundColor,
        child: combatResultsAsyncValue.when(
          data: (combatResults) {
            if (combatResults.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 80, color: hospitalSubTextColor),
                    const SizedBox(height: 20),
                    Text(
                      'Aucun dossier de combat trouvé.\nLancez une simulation pour commencer !',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(fontSize: 18, color: hospitalSubTextColor),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: combatResults.length,
              itemBuilder: (context, index) {
                final combat = combatResults[index];
                final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
                final String formattedDate = formatter.format(combat.combatDate.toDate());

                // Déterminer le texte, la couleur et l'icône en fonction du résultat
                Color outcomeColor;
                IconData outcomeIcon;
                String outcomeText;

                if (combat.attackerWon) {
                  outcomeColor = hospitalPrimaryGreen;
                  outcomeIcon = Icons.check_circle_outline;
                  outcomeText = 'Victoire';
                } else if (combat.winner == 'enemy') { // Si le winner est 'enemy' (défaite)
                  outcomeColor = hospitalErrorColor;
                  outcomeIcon = Icons.cancel_outlined;
                  outcomeText = 'Défaite';
                } else { // 'draw'
                  outcomeColor = hospitalWarningColor;
                  outcomeIcon = Icons.info_outline;
                  outcomeText = 'Égalité';
                }

                return Card(
                  color: hospitalCardColor,
                  elevation: 2.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  child: InkWell( // Utilisez InkWell pour gérer les taps et l'effet visuel
                    onTap: () {
                      // Navigue vers la page de détails en passant l'objet CombatResult
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CombatDetailsPage(combatResult: combat),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12.0), // Assurez-vous que le rayon correspond à celui de la Card
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(
                            outcomeIcon,
                            color: outcomeColor,
                            size: 40,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Conflit contre : ${combat.defenderBaseName ?? 'Base inconnue'}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: hospitalTextColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Date : $formattedDate',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: hospitalSubTextColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Résultat : $outcomeText',
                                  style: GoogleFonts.roboto(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: outcomeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: hospitalSubTextColor, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: hospitalPrimaryGreen),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Erreur lors du chargement de l\'historique: $err',
              style: TextStyle(color: hospitalErrorColor, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}