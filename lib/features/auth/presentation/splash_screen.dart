import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rive/rive.dart';
import '../data/auth_service.dart';

// Locally defined palette tokens based on your specified hex codes
class NewPalette {
  
  static const Color primary = Color(0xFFA7ED10); // Vibrant Lime
  static const Color surfaceMuted = Color(0xFFB5B5B5); // Neutral Gray
  static const Color background = Color(0xFF000000); // Deep Black
  static const Color white = Color(0xFFFFFFFF); // Crisp White

  // Derived style opacities for sleek UI nesting
  static final Color cardBg = surfaceMuted.withOpacity(0.12);
  static final Color border = surfaceMuted.withOpacity(0.25);
  static final Color primarySoft = primary.withOpacity(0.15);
  static final Color textMuted = surfaceMuted.withOpacity(0.7);
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Structural frame execution initialization hold period
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;

    final authService = ref.read(authServiceProvider);
    if (authService.isSignedIn) {
      context.go('/feed');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewPalette.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rive structural runtime instance asset box
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: NewPalette.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: NewPalette.border, width: 1.5),
              ),
              child: const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(22)),
                child: RiveAnimation.asset(
                  'assets/images/welcome2.riv',
                  fit: BoxFit.cover,
                  animations: ['loop', 'idle'], // Fallback structural states
                  placeHolder: Center(
                    child: Text('🫧', style: TextStyle(fontSize: 44)),
                  ),
                ),
              ),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .then(delay: 100.ms)
                .shimmer(
                    duration: 1000.ms,
                    color: NewPalette.primary.withOpacity(0.2)),

            const SizedBox(height: 32),

            const Text(
              'whispr',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: NewPalette.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                fontSize: 44,
              ),
            )
                .animate(delay: 150.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.15, end: 0),

            const SizedBox(height: 8),

            Text(
              'share freely. stay anonymous.',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: NewPalette.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 64),

            // Minimal layout tracker progress loop element configuration
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: NewPalette.primary,
                backgroundColor: NewPalette.primarySoft,
              ),
            ).animate(delay: 450.ms).fadeIn(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
