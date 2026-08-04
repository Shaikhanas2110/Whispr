import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/notification_service.dart';

// Locally defined palette tokens based on your specified hex codes
class NewPalette {
  static bool isDark = true;
  static void sync(BuildContext context) {
    isDark = Theme.of(context).brightness == Brightness.dark;
  }

  static Color get primary =>
      isDark ? const Color(0xFF8C97B8) : const Color(0xFF5B6B8C);
  static Color get background =>
      isDark ? const Color(0xFF0D0D10) : const Color(0xFFFFFFFF);
  static Color get white =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1F);
  static Color get surfaceMuted => const Color(0xFFB5B5B5);

  static Color get cardBg => surfaceMuted.withOpacity(0.12);
  static Color get border => surfaceMuted.withOpacity(0.25);
  static Color get primarySoft => primary.withOpacity(0.15);
  static Color get textMuted => surfaceMuted.withOpacity(0.7);
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    NewPalette.sync(context);
    final notifsAsync = ref.watch(notificationsProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: NewPalette.background,
      appBar: AppBar(
        backgroundColor: NewPalette.background,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'N',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: NewPalette.primary, // Vibrant Lime Accent
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'otifications',
                        style: TextStyle(
                          color: NewPalette.white, // High Contrast Crisp White
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 1),
                  child: Text(
                    'A C T I V I T Y  H U B',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 7.5,
                      fontWeight: FontWeight.w600,
                      color: NewPalette.white.withOpacity(0.35),
                      letterSpacing: 1.5,
                      height: 0.9,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: NewPalette.border),
        ),
        actions: [
          // REDESIGNED: Sleek low-profile action button pill
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            child: TextButton.icon(
              onPressed: uid == null
                  ? null
                  : () =>
                      ref.read(notificationServiceProvider).markAllRead(uid),
              icon: Icon(Icons.done_all_rounded,
                  size: 14, color: NewPalette.primary),
              label: Text(
                'Read all',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: NewPalette.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: NewPalette.primarySoft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                      color: NewPalette.primary.withOpacity(0.2), width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: NewPalette.primary)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (notifs) {
          if (notifs.isEmpty) return const _EmptyState();

          // Group today vs earlier
          final now = DateTime.now();
          final today = notifs
              .where((n) => now.difference(n.createdAt).inHours < 24)
              .toList();
          final earlier = notifs
              .where((n) => now.difference(n.createdAt).inHours >= 24)
              .toList();

          return ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 40),
            children: [
              if (today.isNotEmpty) ...[
                const _SectionLabel(label: 'Today'),
                ...today
                    .asMap()
                    .entries
                    .map((e) => _NotifTile(notif: e.value, index: e.key)),
              ],
              if (earlier.isNotEmpty) ...[
                const _SectionLabel(label: 'Earlier'),
                ...earlier.asMap().entries.map((e) =>
                    _NotifTile(notif: e.value, index: today.length + e.key)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    NewPalette.sync(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: NewPalette.textMuted,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _NotifTile extends ConsumerWidget {
  final WNotification notif;
  final int index;
  const _NotifTile({required this.notif, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    NewPalette.sync(context);
    final cardColor = notif.isRead
        ? NewPalette.cardBg
        : NewPalette.surfaceMuted.withOpacity(0.22);

    return GestureDetector(
      onTap: () {
        if (!notif.isRead) {
          ref.read(notificationServiceProvider).markRead(notif.id);
        }
        if (notif.postId != null) {
          context.push('/post/${notif.postId}');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead
                ? NewPalette.border
                : NewPalette.primary.withOpacity(0.4),
            width: notif.isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          children: [
            // Unread indicator strip
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 4,
              height: 76,
              decoration: BoxDecoration(
                color: notif.isRead ? Colors.transparent : NewPalette.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: NewPalette.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: NewPalette.border),
                    ),
                    child: Center(
                      child: Text(notif.emoji,
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif.title,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: notif.isRead
                                ? FontWeight.w600
                                : FontWeight.w600,
                            color: NewPalette.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          notif.body,
                          style: TextStyle(
                              fontSize: 12, color: NewPalette.surfaceMuted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          timeago.format(notif.createdAt),
                          style: TextStyle(
                              fontSize: 10, color: NewPalette.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 45))
          .fadeIn(duration: 320.ms)
          .slideX(begin: 0.05, end: 0),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    NewPalette.sync(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: NewPalette.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(
                  color: NewPalette.primary.withOpacity(0.2), width: 1.5),
            ),
            child:
                const Center(child: Text('🔔', style: TextStyle(fontSize: 42))),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.08, 1.08),
              duration: 2.seconds),
          const SizedBox(height: 20),
          Text(
            'All caught up!',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: NewPalette.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll let you know when something happens',
            style: TextStyle(fontSize: 13, color: NewPalette.surfaceMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
