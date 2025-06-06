// lib/screens/login_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_widgets/animated_widgets.dart';
import '../state/auth_state_provider.dart';
import 'register_page.dart';
import 'dashboard_page.dart'; // Importez votre DashboardPage ici

// --- Nouvelle Palette de couleurs "Cyber-Tech" (Vert, Bleu Ciel, Jaune Or, Blanc) ---
const Color cyberGreen = Color(0xFF00FF00); // Vert Néon
const Color cyberBlue = Color(0xFF00BFFF); // Bleu Ciel Profond / Azur
const Color cyberGold = Color(0xFFFFD700); // Jaune Or
const Color cyberWhite = Color(0xFFF0F0F0); // Blanc cassé
const Color cyberBlack = Color(0xFF121212); // Noir très foncé
const Color cyberGrey = Color(0xFF333333); // Gris foncé
const double borderRadius = 18.0;

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _glowController;
  late Animation<Color?> _glowAnimation;

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      reverseDuration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = ColorTween(begin: cyberBlue.withOpacity(0.2), end: cyberBlue.withOpacity(0.6)).animate(_glowController);


    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return; // S'assurer que le widget est monté avant d'afficher le SnackBar
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Cache le snackbar précédent
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : cyberGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: cyberBlack,
      body: Stack(
        children: [
          // Effet de fond animé (gradient ou particules)
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cyberGrey.withOpacity(0.4),
                      cyberBlack,
                      cyberGrey.withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [
                      _glowController.value * 0.7,
                      0.5,
                      1.0 - _glowController.value * 0.7,
                    ],
                  ),
                ),
              );
            },
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Hero(
                        tag: 'authLogo',
                        child: Image.asset(
                          'assets/images/logo1.png', // Assurez-vous que ce chemin est correct
                          height: 140,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Text(
                        'Accès Sécurisé au Réseau Immuno-Cyber',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: cyberGreen,
                          shadows: [
                            Shadow(
                              color: cyberGreen.withOpacity(0.6),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Entrez vos crédentiels pour une défense optimale.',
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          color: cyberWhite.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(borderRadius),
                          border: Border.all(color: _glowAnimation.value ?? cyberGrey.withOpacity(0.5), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: _glowAnimation.value?.withOpacity(0.2) ?? Colors.transparent,
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.roboto(color: cyberWhite, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Adresse e-mail',
                                hintStyle: GoogleFonts.roboto(color: cyberWhite.withOpacity(0.5)),
                                prefixIcon: Icon(Icons.person_outline, color: cyberBlue),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: cyberGold, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.roboto(color: cyberWhite, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Mot de passe',
                                hintStyle: GoogleFonts.roboto(color: cyberWhite.withOpacity(0.5)),
                                prefixIcon: Icon(Icons.lock_outline, color: cyberBlue),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: cyberWhite.withOpacity(0.7),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: cyberGold, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: screenWidth * 0.75,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cyberGreen,
                                  foregroundColor: cyberBlack,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(borderRadius),
                                  ),
                                  elevation: 8.0,
                                  shadowColor: cyberGreen.withOpacity(0.6),
                                ),
                                onPressed: _isLoading ? null : () async {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  try {
                                    User? user = await authService.signInWithEmailAndPassword(
                                      emailController.text.trim(), // Trim pour éviter les espaces
                                      passwordController.text.trim(),
                                    );
                                    if (!mounted) return; // Vérification du montage après l'appel async

                                    if (user != null) {
                                      _showSnackBar('Connexion réussie ! Bienvenue, Agent.', isError: false);
                                      // Naviguer vers le tableau de bord après un court délai pour que le snackbar soit visible
                                      Future.delayed(const Duration(seconds: 1), () {
                                        if (mounted) {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (context) => const DashboardPage()),
                                          );
                                        }
                                      });
                                    } else {
                                      // Ce cas est généralement géré par FirebaseAuthException, mais c'est une sécurité
                                      _showSnackBar('Échec de la connexion. Veuillez vérifier vos identifiants.', isError: true);
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    if (!mounted) return;
                                    String message = 'Une erreur est survenue lors de la connexion.';
                                    if (e.code == 'user-not-found' || e.code == 'wrong-password') {
                                      message = 'Crédentiels incorrects. Veuillez vérifier votre e-mail et mot de passe.';
                                    } else if (e.code == 'invalid-email') {
                                      message = 'L\'adresse e-mail n\'est pas valide.';
                                    } else if (e.code == 'network-request-failed') {
                                      message = 'Problème de connexion réseau. Veuillez vérifier votre internet.';
                                    } else {
                                      message = 'Erreur Firebase: ${e.message}';
                                    }
                                    _showSnackBar(message, isError: true);
                                  } catch (e) {
                                    if (!mounted) return;
                                    _showSnackBar('Erreur inattendue: ${e.toString()}', isError: true);
                                  } finally {
                                    if (mounted) { // Assurez-vous que le widget est toujours monté avant de changer l'état
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  }
                                },
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: cyberBlack)
                                    : Text(
                                  'Accéder au Système',
                                  style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterPage()),
                          );
                        },
                        child: Text(
                          'Nouvel Agent ? S\'enregistrer ici',
                          style: GoogleFonts.roboto(
                            color: cyberBlue,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                            decorationColor: cyberBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}