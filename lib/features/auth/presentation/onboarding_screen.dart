import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
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

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  bool _loading = false;

  // Rive Machine State Input Controllers
  StateMachineController? _stateMachineController;
  SMIBool? _identityStateInput;
  SMIBool? _discoveryStateInput;
  SMIBool? _securityStateInput;

  static const _pages = [
    _PageData(
      category: 'Identity',
      stateMachineIndex: 0,
      title: 'Be Truly Yourself',
      subtitle:
          'No name, no face, no judgment.\nShare what you really think instantly.',
    ),
    _PageData(
      category: 'Discovery',
      stateMachineIndex: 1,
      title: 'Find Your Tribe',
      subtitle:
          'Join anonymous communities built specifically around topics you care about.',
    ),
    _PageData(
      category: 'Security',
      stateMachineIndex: 2,
      title: 'Safe & Moderated',
      subtitle:
          'AI-powered moderation systems keep Whispr a safe, healthy space for all.',
    ),
  ];

  void _updateRiveInputs(int activeIndex) {
    if (_stateMachineController == null) return;

    // Set boolean controllers based on active indices cleanly
    _identityStateInput?.value = (activeIndex == 0);
    _discoveryStateInput?.value = (activeIndex == 1);
    _securityStateInput?.value = (activeIndex == 2);
  }

  Future<void> _getStarted() async {
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).signInAnonymously();
      if (mounted) context.go('/feed');
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong: $e',
                style: const TextStyle(
                    fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _stateMachineController?.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: AnimatedSwitcher(
                duration: 300.ms,
                child: Text(
                  _pages[_page].category.toUpperCase(),
                  key: ValueKey(_pages[_page].category),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: NewPalette.textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

            Expanded(
              flex: 5,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: NewPalette.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: NewPalette.border, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: const RiveAnimation.asset(
                      'assets/images/welcome3.riv',
                      fit: BoxFit.contain,
                      placeHolder: Center(
                        child: CircularProgressIndicator(
                            color: NewPalette.primary),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) {
                  setState(() => _page = i);
                  _updateRiveInputs(i);
                },
                itemCount: _pages.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (ctx, i) => _TextContentBlock(data: _pages[i]),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageCtrl,
                    count: _pages.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: NewPalette.primary,
                      dotColor: NewPalette.surfaceMuted,
                      dotHeight: 6,
                      dotWidth: 6,
                      expansionFactor: 3,
                      spacing: 6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AnimatedSwitcher(
                    duration: 200.ms,
                    child: _page < _pages.length - 1
                        ? Row(
                            key: const ValueKey('navigation_action_nodes'),
                            children: [
                              TextButton(
                                onPressed: () => _pageCtrl.animateToPage(
                                  _pages.length - 1,
                                  duration: 500.ms,
                                  curve: Curves.easeOutCubic,
                                ),
                                child: Text(
                                  'Skip',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    color: NewPalette.textMuted,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _pageCtrl.nextPage(
                                  duration: 400.ms,
                                  curve: Curves.easeInOutCubic,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: NewPalette.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: NewPalette.border),
                                  ),
                                  child: const Row(
                                    children: [
                                      Text(
                                        'Next',
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: NewPalette.white,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward_rounded,
                                          size: 16, color: NewPalette.white),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SizedBox(
                            key: const ValueKey('submission_action_node'),
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _getStarted,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: NewPalette.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: NewPalette.background,
                                      ),
                                    )
                                  : const Text(
                                      'Start Whispering →',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: NewPalette.background,
                                      ),
                                    ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  final String category;
  final int stateMachineIndex;
  final String title;
  final String subtitle;
  const _PageData({
    required this.category,
    required this.stateMachineIndex,
    required this.title,
    required this.subtitle,
  });
}

class _TextContentBlock extends StatelessWidget {
  final _PageData data;
  const _TextContentBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Text(
            data.title,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: NewPalette.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('title_${data.title}'))
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 12),
          Text(
            data.subtitle,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: NewPalette.textMuted,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('subtitle_${data.title}'))
              .fadeIn(duration: 400.ms, delay: 100.ms),
        ],
      ),
    );
  }
}
