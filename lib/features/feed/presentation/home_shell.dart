import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';
import '../../notifications/data/notification_service.dart';

class NewPalette {
  static const Color primary = Color(0xFFA7ED10);
  static const Color surfaceMuted = Color(0xFFB5B5B5);
  static const Color background = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static final Color cardBg = surfaceMuted.withOpacity(0.12);
  static final Color border = surfaceMuted.withOpacity(0.25);
  static final Color primarySoft = primary.withOpacity(0.15);
  static final Color textMuted = surfaceMuted.withOpacity(0.7);
}

class HomeShell extends ConsumerWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  int _locationIndex(String location) {
    if (location.startsWith('/communities')) return 1;
    if (location.startsWith('/reels')) return 2;
    if (location.startsWith('/notifications')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _locationIndex(location);
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: NewPalette.background,
      body: child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(currentIndex: idx, unreadCount: unread),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final int unreadCount;
  const _BottomBar({required this.currentIndex, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NewPalette.background,
        border: Border(top: BorderSide(color: NewPalette.border, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: NewPalette.primary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                inactiveIcon: Icons.home_outlined,
                label: 'Home',
                index: 0,
                current: currentIndex,
                onTap: () => context.go('/feed'),
              ),
              _NavItem(
                icon: Icons.auto_awesome_mosaic_rounded,
                inactiveIcon: Icons.auto_awesome_mosaic_outlined,
                label: 'Community',
                index: 1,
                current: currentIndex,
                onTap: () => context.go('/communities'),
              ),
              _NavItem(
                icon: Icons.play_circle_fill_rounded,
                inactiveIcon: Icons.play_circle_outline_rounded,
                label: 'Sparks',
                index: 2,
                current: currentIndex,
                onTap: () => context.push('/reels'),
              ),
              _NavItem(
                icon: Icons.notifications_rounded,
                inactiveIcon: Icons.notifications_outlined,
                label: 'Alerts',
                index: 3,
                current: currentIndex,
                onTap: () => context.go('/notifications'),
                badge: unreadCount,
              ),
              _NavItem(
                icon: Icons.person_rounded,
                inactiveIcon: Icons.person_outlined,
                label: 'Profile',
                index: 4,
                current: currentIndex,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData inactiveIcon;
  final String label;
  final int index;
  final int current;
  final VoidCallback onTap;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.inactiveIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
    this.badge = 0,
  });

  bool get isActive => index == current;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color:
                        isActive ? NewPalette.primarySoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isActive
                        ? Border.all(
                            color: NewPalette.primary.withOpacity(0.2),
                            width: 1)
                        : null,
                  ),
                  child: Icon(
                    isActive ? icon : inactiveIcon,
                    size: 22,
                    color: isActive ? NewPalette.primary : NewPalette.textMuted,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    top: -2,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: NewPalette.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: NewPalette.background, width: 1.5),
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          fontSize: 9,
                          color: NewPalette.background,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: isActive ? NewPalette.primary : NewPalette.textMuted,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
