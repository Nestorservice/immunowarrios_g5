// lib/screens/register_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_widgets/animated_widgets.dart';
import '../state/auth_state_provider.dart';
import '../services/firestore_service.dart';
import 'login_page.dart';

// --- Palette de couleurs "Cyber-Tech" (variante pour l'inscription) ---
const Color registerPrimary = Color(0xFF00BFFF); // Bleu Ciel Profond / Azur
const Color registerSecondary = Color(0xFF00FF00); // Vert Néon
const Color registerGold = Color(0xFFFFD700); // Jaune Or
const Color registerWhite = Color(0xFFF0F0F0); // Blanc cassé
const Color registerBlack = Color(0xFF121212); // Noir très foncé
const Color registerGrey = Color(0xFF333333); // Gris foncé
const double borderRadius = 18.0;

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> with TickerProviderStateMixin {
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
    _glowAnimation = ColorTween(begin: registerPrimary.withOpacity(0.2), end: registerPrimary.withOpacity(0.6)).animate(_glowController);


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
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : registerSecondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final firestoreService = ref.watch(firestoreServiceProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: registerBlack,
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
                      registerGrey.withOpacity(0.4),
                      registerBlack,
                      registerGrey.withOpacity(0.4),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
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
                          'assets/images/logo2.png', // Assurez-vous que ce chemin est correct
                          height: 140,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Text(
                        'Enrôlement dans la Résistance Immunitaire',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: registerPrimary,
                          shadows: [
                            Shadow(
                              color: registerPrimary.withOpacity(0.6),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Rejoignez notre armée de défenseurs contre les menaces.',
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          color: registerWhite.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(borderRadius),
                          border: Border.all(color: _glowAnimation.value ?? registerGrey.withOpacity(0.5), width: 1.5),
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
                              style: GoogleFonts.roboto(color: registerWhite, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Adresse e-mail (votre identifiant)',
                                hintStyle: GoogleFonts.roboto(color: registerWhite.withOpacity(0.5)),
                                prefixIcon: Icon(Icons.email_outlined, color: registerSecondary),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: registerGold, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.roboto(color: registerWhite, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Mot de passe (min. 6 caractères)',
                                hintStyle: GoogleFonts.roboto(color: registerWhite.withOpacity(0.5)),
                                prefixIcon: Icon(Icons.lock_outline, color: registerSecondary),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: registerWhite.withOpacity(0.7),
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
                                  borderSide: BorderSide(color: registerGold, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: screenWidth * 0.75,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: registerPrimary,
                                  foregroundColor: cyberBlack,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(borderRadius),
                                  ),
                                  elevation: 8.0,
                                  shadowColor: registerPrimary.withOpacity(0.6),
                                ),
                                onPressed: _isLoading ? null : () async {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  if (passwordController.text.trim().length < 6) {
                                    _showSnackBar('Le mot de passe doit contenir au moins 6 caractères.', isError: true);
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    return;
                                  }
                                  try {
                                    User? user = await authService.signUpWithEmailAndPassword(
                                      emailController.text.trim(),
                                      passwordController.text.trim(),
                                    );
                                    if (!mounted) return;

                                    if (user != null) {
                                      await firestoreService.createUserProfile(
                                        userId: user.uid,
                                        email: user.email!,
                                      );
                                      _showSnackBar('Cyber-Profil créé avec succès ! Bienvenue, Agent.', isError: false);
                                      // Retour à la page de connexion après un court délai
                                      Future.delayed(const Duration(seconds: 1), () {
                                        if (mounted) {
                                          Navigator.pop(context);
                                        }
                                      });
                                    } else {
                                      // Ce cas est généralement géré par FirebaseAuthException
                                      _showSnackBar('Échec de l\'inscription. Veuillez réessayer.', isError: true);
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    if (!mounted) return;
                                    String message = 'Une erreur est survenue lors de l\'inscription.';
                                    if (e.code == 'weak-password') {
                                      message = 'Mot de passe trop faible.';
                                    } else if (e.code == 'email-already-in-use') {
                                      message = 'Cet e-mail est déjà utilisé. Veuillez vous connecter.';
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
                                    if (mounted) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  }
                                },
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: cyberBlack)
                                    : Text(
                                  'Rejoindre la Résistance',
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
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Déjà enrôlé ? Connectez-vous ici',
                          style: GoogleFonts.roboto(
                            color: registerSecondary,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                            decorationColor: registerSecondary,
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