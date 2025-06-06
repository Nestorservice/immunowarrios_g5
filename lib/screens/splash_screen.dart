// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:google_fonts/google_fonts.h';
import 'dart:async'; // For Future.delayed

import 'auth_checker.dart'; // <<< CORRECTED IMPORT: Navigate to AuthChecker


// --- Theme colors (can be imported from your color file if you have one) ---
const Color hospitalPrimaryGreen = Color(0xFF4CAF50); // Medical Green
const Color hospitalAccentPink = Color(0xFFE91E63); // Vivid Pink
const Color hospitalBackgroundColor = Color(0xFFF5F5F5); // Light background
const Color hospitalTextColor = Color(0xFF212121); // Dark text

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Controller for the text opacity animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Duration for text appearance
    );

    // Opacity animation
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn, // Smooth animation for appearance
    );

    // Start text animation
    _controller.forward();

    // Wait for 5 seconds before navigating to the authentication checker
    Timer(const Duration(seconds: 5), () {
      // Ensure the widget is still mounted before navigating
      if (mounted) {
        // Navigate to AuthChecker after the splash screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthChecker()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Release AnimationController resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hospitalBackgroundColor, // Background color if image doesn't cover all
      body: Stack(
        fit: StackFit.expand, // Image will cover the whole screen
        children: [
          // 1. Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/splash_background.png'), // <<< YOUR IMAGE PATH HERE
                fit: BoxFit.cover, // Image will cover the entire screen
              ),
            ),
          ),
          // 2. Semi-transparent overlay to improve text readability
          Container(
            color: Colors.black.withOpacity(0.4), // A 40% dark overlay
          ),
          // 3. Centered welcome message
          Center(
            child: FadeTransition( // Fade animation for text
              opacity: _animation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main title
                  Text(
                    'Bienvenue, nouveau Docteur dans notre jeu nommé : ImmunoWarriors !', // <<< YOUR WELCOME MESSAGE
                    style: GoogleFonts.montserrat(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // White text on dark background
                      shadows: [
                        Shadow(
                          offset: const Offset(2.0, 2.0),
                          blurRadius: 3.0,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  // Subtitle or Slogan
                  Text(
                    'Découvrez ImmunoWarriors : La Science au Service de la Victoire.', // <<< YOUR SLOGAN
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.8), // Slightly transparent text
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 50), // Space below text
                  // You can add a small loading indicator if you wish
                  CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(hospitalPrimaryGreen), // Green
                    strokeWidth: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}