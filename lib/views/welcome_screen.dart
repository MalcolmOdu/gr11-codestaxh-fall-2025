import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/glitch_text.dart';


class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();


    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();

    // Auto-navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    final user = FirebaseAuth.instance.currentUser;
    final homeRoute = kIsWeb ? '/dashboard' : '/snippets';

    if (user != null) {
      context.go(homeRoute);
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '</>',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Brand name with glitch effect
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'CODE',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const GlitchText(
                      text: 'STAXH',
                      duration: Duration(milliseconds: 2000),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Tagline
                Text(
                  'Stash your code, retrieve it anywhere',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),


                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}