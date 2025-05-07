import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/bacterie.dart';
import '../models/base_virale.dart';
import '../models/virus.dart';
import '../state/auth_state_provider.dart'; // Importe TOUS nos providers (et potentiellement UserResources/UserProfile)
// Importe les pages pour la navigation future
import 'scanner_page.dart';
import 'bio_forge_page.dart';
import 'laboratoire_rd_page.dart';
// import 'archives_guerre_page.dart';
// Importe Google Fonts (ASSURE-TOI D'AVOIR AJOUTÉ LA DÉPENDANCE google_fonts dans pubspec.yaml)
import 'package:google_fonts/google_fonts.dart';
// Importe FirestoreService
import '../services/firestore_service.dart';


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


class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtient l'instance de AuthService via le provider pour la déconnexion
    final authService = ref.watch(authServiceProvider);
    // Regarde l'état d'authentification pour obtenir l'utilisateur connecté (AsyncValue)
    final authState = ref.watch(authStateChangesProvider);
    // Regarde les données de ressources de l'utilisateur via userResourcesProvider.
    final userResources = ref.watch(userResourcesProvider);
    // Obtient l'AsyncValue du profil complet (dont dépendent les ressources)
    final userProfileAsyncValue = ref.watch(userProfileProvider);
    // Obtient l'instance de FirestoreService (Provider)
    final firestoreService = ref.watch(firestoreServiceProvider);


    return Scaffold(
      // AppBar thématique claire et propre
      appBar: AppBar(
        title: Text(
          'Tableau de Bord Immunowarriors', // Titre plus explicite
          style: GoogleFonts.poppins( // Police propre pour le titre de l'AppBar
            color: hospitalTextColor, // Texte sombre
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: hospitalBackgroundColor, // Fond clair de l'AppBar
        elevation: 1.0, // Légère ombre pour la distinction
        centerTitle: true,
      ),
      // Corps avec fond clair
      body: Container(
        color: hospitalBackgroundColor, // Fond très clair pour le corps
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0), // Padding général autour du contenu
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Étirer les éléments
            children: [
              // --- Section Bienvenue & Utilisateur (Stylisation hospitalière) ---
              authState.when(
                data: (user) {
                  if (user != null && user.email != null) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.local_hospital_outlined, size: 45, color: hospitalPrimaryGreen), // Icône hôpital ou santé
                        const SizedBox(width: 15), // Espace
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bienvenue, Dr. ${user.email!.split('@').first} !', // Message plus contextuel
                                style: GoogleFonts.montserrat( // Police pour le message d'accueil
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: hospitalTextColor, // Texte sombre
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Statut: Connecté', // Statut de connexion
                                style: GoogleFonts.roboto( // Police standard pour l'email
                                  fontSize: 14,
                                  color: hospitalSubTextColor, // Texte gris
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
                // Gère les états de chargement et d'erreur
                loading: () => Center(child: CircularProgressIndicator(color: hospitalPrimaryGreen)), // Indicateur vert
                error: (err, stack) => Center(child: Text('Erreur utilisateur : $err', style: TextStyle(color: hospitalErrorColor))), // Message d'erreur rouge
              ),
              const SizedBox(height: 40), // Espace
              // --- Panneau des Ressources (Design "dossier médical" ou "affichage clinique") ---
              _buildResourcesPanel(userResources, userProfileAsyncValue),
              const SizedBox(height: 40), // Espace
              // --- Titre de la section Navigation ---
              Text(
                'Départements Cliniques', // Titre de section style hôpital
                style: GoogleFonts.poppins( // Titre de section avec police propre et couleur verte
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: hospitalPrimaryGreen,
                ),
                textAlign: TextAlign.center, // Centre le titre
              ),
              const SizedBox(height: 25), // Espace
              // --- Grille / Tuiles de Navigation (Le cœur du design hospitalier) ---
              Wrap(
                spacing: 15.0, // Espace horizontal
                runSpacing: 15.0, // Espace vertical
                alignment: WrapAlignment.center, // Centre l'ensemble des tuiles
                children: [
                  // Appelle le widget helper pour chaque tuile de navigation
                  _buildNavigationTile( // Tuile pour le Scanner
                    context,
                    'Diagnostic Viral', // Texte adapté au thème
                    Icons.search, // Icône de recherche/diagnostic
                        () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerPage()));
                    },
                    hospitalAccentPink, // Couleur rose pour l'accent
                  ),
                  _buildNavigationTile( // Tuile pour la Bio-Forge
                    context,
                    'Pharmacie Synthétique', // Texte adapté au thème
                    Icons.medical_services_outlined, // Icône de services médicaux/pharmacie
                        () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const BioForgePage()));
                    },
                    hospitalPrimaryGreen, // Couleur verte
                  ),
                  _buildNavigationTile( // Tuile pour le Laboratoire R&D
                    context,
                    'Laboratoire R&D', // Peut rester, ou "Recherche Clinique"
                    Icons.biotech_outlined, // Icône labo
                        () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LaboratoireRDPage()));
                    },
                    hospitalWarningColor, // Couleur orange (recherche expérimentale)
                  ),
                  // Tuile pour les Archives (désactivée)
                  _buildNavigationTile(
                    context,
                    'Dossiers Patients', // Texte adapté
                    Icons.folder_shared_outlined, // Icône dossiers
                        () { print("TODO: Naviguer vers les Archives de Guerre"); },
                    hospitalSubTextColor.withOpacity(0.5), // Grisé
                    enabled: false,
                  ),
                  // Tuile pour le Simulateur de Combat (désactivée)
                  _buildNavigationTile(
                    context,
                    'Simulation Thérapeutique', // Texte adapté
                    Icons.monitor_heart_outlined, // Icône moniteur cardiaque/simulation
                        () { print("TODO: Lancer un Combat (Simulateur)"); },
                    hospitalSubTextColor.withOpacity(0.5), // Grisé
                    enabled: false,
                  ),
                  // Ajoute d'autres tuiles ici en appelant _buildNavigationTile
                ],
              ),
              const SizedBox(height: 40), // Espace
              // --- Titre de la section Actions Secondaires ---
              Text(
                'Systèmes de Gestion', // Titre de section pour les actions
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: hospitalSubTextColor, // Couleur gris pour cette section moins prioritaire
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15), // Espace
              // --- Actions Secondaires (Sauvegarde, Déconnexion) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Bouton Sauvegarder Base
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hospitalCardColor, // Fond blanc
                          foregroundColor: hospitalPrimaryGreen, // Texte vert
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(color: hospitalPrimaryGreen.withOpacity(0.5)), // Bordure légère
                          ),
                          elevation: 1.0, // Légère ombre
                        ),
                        onPressed: () async {
                          // Logique de sauvegarde existante
                          final currentUser = ref.read(authStateChangesProvider).value;
                          if (currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Impossible de sauvegarder : connectez-vous d\'abord.')),
                            );
                            return;
                          }
                          final currentContext = context;
                          final currentUserRef = ref;
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
                            // Assurez-vous que FirestoreService est accessible via ref
                            final firestoreService = ref.read(firestoreServiceProvider);
                            await firestoreService.savePlayerBase(userId: currentUser.uid, base: baseExemple);
                            if (!currentUserRef.context.mounted) return;
                            ScaffoldMessenger.of(currentContext).showSnackBar(
                              const SnackBar(content: Text('Base virale exemple sauvegardée !')),
                            );
                            print('Base virale exemple sauvegardée pour ${currentUser.uid}');
                          } catch (e) {
                            if (!currentUserRef.context.mounted) return;
                            ScaffoldMessenger.of(currentContext).showSnackBar(
                              SnackBar(content: Text('Erreur lors de la sauvegarde : ${e.toString()}')),
                            );
                            print('Erreur lors de la sauvegarde de la base : $e');
                          }
                        },
                        child: Text('Sauvegarder', style: GoogleFonts.roboto(fontSize: 14)), // Texte standard
                      ),
                    ),
                  ),
                  // Bouton Déconnexion
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hospitalErrorColor, // Fond rouge pour déconnexion
                          foregroundColor: Colors.white, // Texte blanc
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                          elevation: 1.0,
                        ),
                        onPressed: () async {
                          // Logique de déconnexion existante
                          final currentContext = context;
                          final currentUserRef = ref;
                          try {
                            // Assurez-vous que AuthService est accessible via ref
                            final authService = ref.read(authServiceProvider);
                            await authService.signOut();
                            if (!currentUserRef.context.mounted) return;
                            ScaffoldMessenger.of(currentContext).showSnackBar(
                              const SnackBar(content: Text('Déconnexion réussie !')),
                            );
                          } catch (e) {
                            if (!currentUserRef.context.mounted) return;
                            ScaffoldMessenger.of(currentContext).showSnackBar(
                              SnackBar(content: Text('Erreur lors de la déconnexion : ${e.toString()}')),
                            );
                          }
                        },
                        child: Text('Déconnexion', style: GoogleFonts.roboto(fontSize: 14)), // Texte standard
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Espace
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets helper pour le design (adaptés au thème hospitalier) ---

  // Widget pour le Panneau des Ressources
  Widget _buildResourcesPanel(var userResources, AsyncValue<Object?> userProfileAsyncValue) {
    // Ajout d'une vérification pour firestoreServiceProvider si nécessaire ici,
    // mais il est déjà utilisé dans le build, donc son provider doit être accessible.
    // Si vous aviez besoin du service dans _buildResourcesPanel, vous devriez le passer en paramètre
    // ou le lire via ref si _buildResourcesPanel était un ConsumerWidget/StatelessWidget.
    // Comme il n'est pas utilisé ici, pas besoin de l'ajouter en paramètre.

    return Card(
      color: hospitalCardColor, // Fond blanc propre
      elevation: 2.0, // Légère ombre
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Coins légèrement arrondis
      child: Padding(
        padding: const EdgeInsets.all(20.0), // Padding intérieur
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vitalité du Système Immunitaire :', // Titre adapté
              style: GoogleFonts.poppins( // Police et couleur pour le titre
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: hospitalPrimaryGreen,
              ),
            ),
            const Divider(color: hospitalSubTextColor, height: 25, thickness: 0.5), // Ligne de séparation plus fine
            if (userResources != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround, // Espace également
                children: [
                  // Affichage Énergie
                  Column(
                    children: [
                      Icon(Icons.power_settings_new, size: 35, color: hospitalAccentPink), // Icône énergie (rose pour accent)
                      const SizedBox(height: 4),
                      Text(
                        'Énergie Cellulaire', // Label adapté
                        style: GoogleFonts.roboto(fontSize: 16, color: hospitalSubTextColor), // Police et couleur
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // Adapter ici : si userResources.energie donne une erreur, utilise userResources['energie']
                        // ou assure-toi que UserResources est bien défini et importé.
                        userResources.energie.toStringAsFixed(1), // Affiche la valeur
                        style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: hospitalTextColor), // Police et couleur
                      ),
                    ],
                  ),
                  // Séparateur vertical
                  Container(
                    height: 60,
                    width: 1,
                    color: hospitalSubTextColor.withOpacity(0.3), // Couleur très claire
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  // Affichage Bio-matériaux
                  Column(
                    children: [
                      Icon(Icons.auto_fix_high, size: 35, color: hospitalPrimaryGreen), // Icône bio-matériaux (vert)
                      const SizedBox(height: 4),
                      Text(
                        'Substances Vitales', // Label adapté
                        style: GoogleFonts.roboto(fontSize: 16, color: hospitalSubTextColor), // Police et couleur
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // Adapter ici : si userResources.bioMateriaux donne une erreur, utilise userResources['bioMateriaux']
                        // ou assure-toi que UserResources est bien défini et importé.
                        userResources.bioMateriaux.toStringAsFixed(1), // Affiche la valeur
                        style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: hospitalTextColor), // Police et couleur
                      ),
                    ],
                  ),
                ],
              )
            else
            // Gère les états de chargement/erreur
              userProfileAsyncValue.when(
                data: (_) => Center(child: Text('Chargement des données vitales...', style: GoogleFonts.roboto(color: hospitalSubTextColor, fontStyle: FontStyle.italic))), // Message stylisé
                loading: () => Center(child: CircularProgressIndicator(color: hospitalPrimaryGreen)), // Indicateur vert
                error: (err, stack) => Center(child: Text('Erreur chargement données : ${err.toString()}', style: TextStyle(color: hospitalErrorColor))), // Message d'erreur rouge
              ),
          ],
        ),
      ),
    );
  }

  // Widget pour une Tuile de Navigation stylisée (thème hospitalier)
  Widget _buildNavigationTile(BuildContext context, String text, IconData icon, VoidCallback onPressed, Color color, {bool enabled = true}) {
    return Card(
      color: hospitalCardColor, // Fond blanc
      elevation: enabled ? 4.0 : 1.0, // Ombre selon état
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0), // Coins arrondis
        side: enabled ? BorderSide(color: color.withOpacity(0.2), width: 1.0) : BorderSide.none, // Bordure légère si activé
      ),
      // Taille fixe pour chaque tuile
      child: SizedBox(
        width: 150, // Largeur ajustée légèrement pour tenir dans un Wrap plus facilement
        height: 150, // Hauteur
        child: InkWell( // Clicable avec effet visuel
          borderRadius: BorderRadius.circular(10.0),
          onTap: enabled ? onPressed : null, // Action si activé
          child: Padding(
            padding: const EdgeInsets.all(12.0), // Padding intérieur
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Centre le contenu
              children: [
                Icon(
                  icon, // Icône
                  size: 55, // Taille de l'icône
                  color: enabled ? color : hospitalSubTextColor.withOpacity(0.5), // Couleur selon état
                ),
                const SizedBox(height: 10), // Espace
                Text(
                  text, // Texte de la tuile
                  textAlign: TextAlign.center, // Centre le texte
                  style: GoogleFonts.poppins( // Police pour le texte de la tuile
                    fontSize: 16,
                    fontWeight: FontWeight.w500, // Poids moins gras
                    color: enabled ? hospitalTextColor : hospitalSubTextColor.withOpacity(0.5), // Couleur texte selon état
                  ),
                  overflow: TextOverflow.ellipsis, // Coupe si trop long
                  maxLines: 2, // Max deux lignes
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}