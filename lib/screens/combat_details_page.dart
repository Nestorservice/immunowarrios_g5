// lib/screens/combat_details_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Pour formater les dates

import '../models/combat_result.dart'; // Importe ton modèle CombatResult

// Couleurs thématiques (définies ici pour être autonomes)
const Color hospitalPrimaryGreen = Color(0xFF4CAF50);
const Color hospitalAccentPink = Color(0xFFE91E63);
const Color hospitalBackgroundColor = Color(0xFFF5F5F5);
const Color hospitalCardColor = Color(0xFFFFFFFF);
const Color hospitalTextColor = Color(0xFF212121);
const Color hospitalSubTextColor = Color(0xFF757575);
const Color hospitalWarningColor = Color(0xFFFF9800);
const Color hospitalErrorColor = Color(0xFFF44336);


class CombatDetailsPage extends StatelessWidget {
  final CombatResult combatResult;

  const CombatDetailsPage({super.key, required this.combatResult});

  @override
  Widget build(BuildContext context) {
    // Formatte la date pour un affichage lisible
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    final String formattedDate = formatter.format(combatResult.combatDate.toDate());

    // Détermine les couleurs et textes en fonction du résultat
    Color outcomeColor;
    String outcomeText;
    IconData outcomeEmoji;

    if (combatResult.attackerWon) {
      outcomeColor = hospitalPrimaryGreen;
      outcomeText = 'Victoire !';
      outcomeEmoji = Icons.emoji_events; // Icône de victoire
    } else if (combatResult.winner == 'enemy') {
      outcomeColor = hospitalErrorColor;
      outcomeText = 'Défaite...';
      outcomeEmoji = Icons.mood_bad; // Icône de défaite
    } else {
      outcomeColor = hospitalWarningColor;
      outcomeText = 'Égalité.';
      outcomeEmoji = Icons.balance; // Icône d'équilibre/égalité
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détails du Dossier',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: hospitalPrimaryGreen,
        elevation: 1.0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: hospitalBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre et informations de base
            Text(
              'Rapport de Conflit du ${formattedDate}',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: hospitalTextColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Adversaire : ${combatResult.defenderBaseName}',
              style: GoogleFonts.roboto(fontSize: 16, color: hospitalSubTextColor),
            ),
            const SizedBox(height: 20),

            // Panneau des résultats clés
            Card(
              color: hospitalCardColor,
              elevation: 2.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Issue du Combat :',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: hospitalTextColor,
                      ),
                    ),
                    const Divider(height: 16, thickness: 0.5, color: hospitalSubTextColor),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          outcomeText,
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: outcomeColor,
                          ),
                        ),
                        Icon(
                          outcomeEmoji,
                          color: outcomeColor,
                          size: 36,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Votre équipe : ${combatResult.playerPathogensRemaining} pathogènes restants',
                      style: GoogleFonts.roboto(fontSize: 16, color: hospitalTextColor),
                    ),
                    Text(
                      'Équipe ennemie : ${combatResult.enemyPathogensRemaining} pathogènes restants',
                      style: GoogleFonts.roboto(fontSize: 16, color: hospitalTextColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Journal détaillé du combat
            Text(
              'Journal Détaillé du Combat :',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: hospitalPrimaryGreen,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: hospitalCardColor,
              elevation: 2.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: combatResult.combatLog.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      entry,
                      style: GoogleFonts.roboto(fontSize: 13, color: hospitalSubTextColor),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}