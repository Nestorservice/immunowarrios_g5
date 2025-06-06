// lib/screens/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bacterie.dart';
import '../models/base_virale.dart';
import '../models/virus.dart';
import '../models/combat_result.dart' as app_combat_result;

import '../state/auth_state_provider.dart';
import '../services/firestore_service.dart';
import '../services/combat_service.dart';
import '../models/laboratoire_recherche.dart';

import 'combat_history_page.dart';
import 'scanner_page.dart';
import 'bio_forge_page.dart';
import 'laboratoire_rd_page.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ai_advisor_page.dart';
import 'combat_visualization_page.dart'; // <<< NOUVEL IMPORT : La page de visualisation de combat


// --- Nouvelle Palette de couleurs thématique "Immuno-Médical" (clair, propre) ---
// Utilise ces couleurs pour l'ambiance hospitalière
const Color hospitalPrimaryGreen = Color(0xFF4CAF50); // Vert Médical (Principal, Thème)
const Color hospitalAccentPink = Color(0xFFE91E63); // Rose Vif (Accent, Attention)
const Color hospitalBackgroundColor = Color(0xFFF5F5F5); // Fond clair principal (Gris très clair)
const Color hospitalCardColor = Color(0xFFFFFFFF); // Fond blanc pour les panneaux / cartes (Propre)
const Color hospitalTextColor = Color(0xFF212121); // Texte sombre sur fond clair (Lecture facile)
const Color hospitalSubTextColor = Color(0xFF757575); // Texte moins important / labels (Gris moyen)
const Color hospitalWarningColor = Color(0xFFFF9800); // Orange (Avertissement, R&D)
const Color hospitalErrorColor = Color(0xFFF44336); // Rouge Vif (Erreur, Déconnexion)
const Color hospitalSuccessColor = hospitalPrimaryGreen; // Pour les messages de succès


class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final authState = ref.watch(authStateChangesProvider);
    final userResources = ref.watch(userResourcesProvider);
    final userProfileAsyncValue = ref.watch(userProfileProvider);
    final firestoreService = ref.watch(firestoreServiceProvider);
    // Le CombatService n'a plus besoin d'être instancié ici pour la simulation directe
    // car on va naviguer vers une page dédiée.

    // Liste des tuiles de navigation
    final List<Map<String, dynamic>> navigationTiles = [
      {
        'text': 'Diagnostic Viral',
        'icon': Icons.search,
        'onPressed': () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerPage()));
        },
        'color': hospitalAccentPink,
      },
      {
        'text': 'Pharmacie Synthétique',
        'icon': Icons.medical_services_outlined,
        'onPressed': () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const BioForgePage()));
        },
        'color': hospitalPrimaryGreen,
      },
      {
        'text': 'Laboratoire R&D',
        'icon': Icons.biotech_outlined,
        'onPressed': () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const LaboratoireRDPage()));
        },
        'color': hospitalWarningColor,
      },
      {
        'text': 'Dossiers Patients',
        'icon': Icons.folder_shared_outlined,
        'onPressed': () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CombatHistoryPage()));
        },
        'color': hospitalAccentPink,
      },
      {
        'text': 'Simulation Thérapeutique',
        'icon': Icons.monitor_heart_outlined,
        'onPressed': () async {
          final currentUser = ref.read(authStateChangesProvider).value;
          if (currentUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Connectez-vous pour lancer une simulation de combat.')),
            );
            return;
          }

          // Création d'une base exemple pour le joueur
          final playerBase = BaseVirale(
            id: currentUser.uid,
            nom: 'Base de ${currentUser.email?.split('@').first ?? 'CyberGuerrier'}',
            createurId: currentUser.uid,
            pathogenes: [
              Virus(id: const Uuid().v4(), pv: 50.0, maxPv: 50.0, armure: 5.0, typeAttaque: 'corrosive', degats: 10.0, initiative: 15, faiblesses: {'physique': 1.5, 'energetique': 0.5}),
              Virus(id: const Uuid().v4(), pv: 60.0, maxPv: 60.0, armure: 8.0, typeAttaque: 'perforante', degats: 12.0, initiative: 12, faiblesses: {'chimique': 1.5}),
              Bacterie(id: const Uuid().v4(), pv: 100.0, maxPv: 100.0, armure: 10.0, typeAttaque: 'physique', degats: 8.0, initiative: 10, faiblesses: {'energetique': 1.5, 'physique': 0.8}),
            ],
          );

          // Création d'une base ennemie fictive pour la simulation
          final enemyBase = BaseVirale(
            id: const Uuid().v4(),
            nom: 'Base du Contre-Attaque Alpha',
            createurId: 'system_ai_001',
            pathogenes: [
              Virus(id: const Uuid().v4(), pv: 45.0, maxPv: 45.0, armure: 3.0, typeAttaque: 'energetique', degats: 9.0, initiative: 16, faiblesses: {'physique': 1.5}),
              Bacterie(id: const Uuid().v4(), pv: 90.0, maxPv: 90.0, armure: 7.0, typeAttaque: 'chimique', degats: 7.0, initiative: 11, faiblesses: {'corrosive': 1.5}),
              Virus(id: const Uuid().v4(), pv: 55.0, maxPv: 55.0, armure: 6.0, typeAttaque: 'corrosive', degats: 11.0, initiative: 14, faiblesses: {'energetique': 1.5}),
            ],
          );

          // Naviguer vers la nouvelle page de visualisation du combat
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CombatVisualizationPage(
                playerBase: playerBase,
                enemyBase: enemyBase,
              ),
            ),
          );
        },
        'color': hospitalPrimaryGreen,
      },
      {
        'text': 'Conseiller IA',
        'icon': Icons.psychology_outlined,
        'onPressed': () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AiAdvisorPage()));
        },
        'color': hospitalWarningColor,
      },
    ];


    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tableau de Bord Immunowarriors',
          style: GoogleFonts.poppins(
            color: hospitalTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: hospitalBackgroundColor,
        elevation: 1.0,
        centerTitle: true,
      ),
      body: Container(
        color: hospitalBackgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              authState.when(
                data: (user) {
                  if (user != null && user.email != null) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.local_hospital_outlined, size: 45, color: hospitalPrimaryGreen),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bienvenue, Dr. ${user.email!.split('@').first} !',
                                style: GoogleFonts.montserrat(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: hospitalTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Statut: Connecté',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: hospitalSubTextColor,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => Center(child: CircularProgressIndicator(color: hospitalPrimaryGreen)),
                error: (err, stack) => Center(child: Text('Erreur utilisateur : $err', style: TextStyle(color: hospitalErrorColor))),
              ),
              const SizedBox(height: 40),
              _buildResourcesPanel(userResources, userProfileAsyncValue),
              const SizedBox(height: 40),
              Text(
                'Départements Cliniques',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: hospitalPrimaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              // NOUVEAU : Utilisation de GridView.builder pour les tuiles 2x2
              GridView.builder(
                shrinkWrap: true, // Pour que le GridView prenne juste la taille nécessaire
                physics: const NeverScrollableScrollPhysics(), // Désactive le scroll du GridView (car on a déjà un SingleChildScrollView parent)
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 tuiles par ligne
                  crossAxisSpacing: 15.0, // Espacement horizontal entre les tuiles
                  mainAxisSpacing: 15.0, // Espacement vertical entre les tuiles
                  childAspectRatio: 1.0, // Ratio largeur/hauteur pour des tuiles carrées
                ),
                itemCount: navigationTiles.length,
                itemBuilder: (context, index) {
                  final tile = navigationTiles[index];
                  return _buildNavigationTile(
                    context,
                    tile['text'],
                    tile['icon'],
                    tile['onPressed'],
                    tile['color'],
                    enabled: true, // Toutes les tuiles sont actives par défaut ici
                  );
                },
              ),
              const SizedBox(height: 40),
              Text(
                'Systèmes de Gestion',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: hospitalSubTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hospitalCardColor,
                          foregroundColor: hospitalPrimaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(color: hospitalPrimaryGreen.withOpacity(0.5)),
                          ),
                          elevation: 1.0,
                        ),
                        onPressed: () async {
                          final currentUser = ref.read(authStateChangesProvider).value;
                          if (currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Impossible de sauvegarder : connectez-vous d\'abord.')),
                            );
                            return;
                          }
                          final currentContext = context;
                          final baseExemple = BaseVirale(
                            id: currentUser.uid,
                            nom: 'Base de ${currentUser.email?.split('@').first ?? 'CyberGuerrier'}',
                            createurId: currentUser.uid,
                            pathogenes: [
                              Virus(id: const Uuid().v4(), pv: 50.0, maxPv: 50.0, armure: 5.0, typeAttaque: 'corrosive', degats: 10.0, initiative: 15, faiblesses: {'physique': 1.5, 'energetique': 0.5}),
                              Virus(id: const Uuid().v4(), pv: 60.0, maxPv: 60.0, armure: 8.0, typeAttaque: 'perforante', degats: 12.0, initiative: 12, faiblesses: {'chimique': 1.5}),
                              Bacterie(id: const Uuid().v4(), pv: 100.0, maxPv: 100.0, armure: 10.0, typeAttaque: 'physique', degats: 8.0, initiative: 10, faiblesses: {'energetique': 1.5, 'physique': 0.8}),
                            ],
                          );
                          try {
                            final firestoreService = ref.read(firestoreServiceProvider);
                            await firestoreService.savePlayerBase(userId: currentUser.uid, base: baseExemple);
                            if (!currentContext.mounted) return;
                            ScaffoldMessenger.of(currentContext).showSnackBar(
                              const SnackBar(content: Text('Base virale exemple sauvegardée !')),
                            );
                            print('Base virale exemple sauvegardée pour ${currentUser.uid}');
                          } catch (e) {
                            if (!currentContext.mounted) return;
                            ScaffoldMessenger.of(currentContext).showSnackBar(
                              SnackBar(content: Text('Erreur lors de la sauvegarde : ${e.toString()}')),
                            );
                            print('Erreur lors de la sauvegarde de la base : $e');
                          }
                        },
                        child: Text('Sauvegarder Base', style: GoogleFonts.roboto(fontSize: 14)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hospitalErrorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                          elevation: 1.0,
                        ),
                        onPressed: () async {
                          final currentContext = context;
                          try {
                            final authService = ref.read(authServiceProvider);
                            await authService.signOut();
                            if (!currentContext.mounted) return;
                            ScaffoldMessenger.of(currentContext).showSnackBar(
                              const SnackBar(content: Text('Déconnexion réussie !')),
                            );
                          } catch (e) {
                            if (!currentContext.mounted) return;
                            ScaffoldMessenger.of(currentContext).showSnackBar(
                              SnackBar(content: Text('Erreur lors de la déconnexion : ${e.toString()}')),
                            );
                          }
                        },
                        child: Text('Déconnexion', style: GoogleFonts.roboto(fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourcesPanel(var userResources, AsyncValue<Object?> userProfileAsyncValue) {
    return Card(
      color: hospitalCardColor,
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vitalité du Système Immunitaire :',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: hospitalPrimaryGreen,
              ),
            ),
            const Divider(color: hospitalSubTextColor, height: 25, thickness: 0.5),
            if (userResources != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Utilisation d'Expanded pour que les colonnes prennent l'espace disponible équitablement
                  Expanded(
                    child: Column(
                      children: [
                        Icon(Icons.power_settings_new, size: 35, color: hospitalAccentPink),
                        const SizedBox(height: 4),
                        Text(
                          'Énergie Cellulaire',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(fontSize: 16, color: hospitalSubTextColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userResources.energie.toStringAsFixed(1),
                          style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: hospitalTextColor),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 60,
                    width: 1,
                    color: hospitalSubTextColor.withOpacity(0.3),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Icon(Icons.auto_fix_high, size: 35, color: hospitalPrimaryGreen),
                        const SizedBox(height: 4),
                        Text(
                          'Substances Vitales',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(fontSize: 16, color: hospitalSubTextColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userResources.bioMateriaux.toStringAsFixed(1),
                          style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: hospitalTextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              userProfileAsyncValue.when(
                data: (_) => Center(child: Text('Chargement des données vitales...', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic))),
                loading: () => Center(child: CircularProgressIndicator(color: hospitalPrimaryGreen)),
                error: (err, stack) => Center(child: Text('Erreur chargement données : ${err.toString()}', style: TextStyle(color: hospitalErrorColor))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTile(BuildContext context, String text, IconData icon, VoidCallback onPressed, Color color, {bool enabled = true}) {
    return Card(
      color: hospitalCardColor,
      elevation: enabled ? 4.0 : 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: enabled ? BorderSide(color: color.withOpacity(0.2), width: 1.0) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.0),
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 50,
                color: enabled ? color : hospitalSubTextColor.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: enabled ? hospitalTextColor : hospitalSubTextColor.withOpacity(0.5),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}