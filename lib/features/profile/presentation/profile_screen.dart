import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../auth/data/auth_service.dart';
import '../../auth/domain/user_model.dart';
import '../../../shared/widgets/w_avatar.dart';
import '../../../app/constants.dart';
import '../../community/data/community_service.dart'; // Ensure this matches your public provider location path

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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: NewPalette.background,
      appBar: AppBar(
        backgroundColor: NewPalette.background,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('👤', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: const TextSpan(
                    text: 'P',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: NewPalette.primary,
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'rofile',
                        style: TextStyle(
                          color: NewPalette.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 1),
                  child: Text(
                    'U S E R  S E T T I N G S',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
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
          GestureDetector(
            onTap: () => _showSettings(context, ref),
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: NewPalette.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NewPalette.border),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: NewPalette.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: NewPalette.primary)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (user) => user == null
            ? const Center(
                child: Text('Not signed in',
                    style: TextStyle(
                        fontFamily: 'Nunito', color: NewPalette.white)))
            : _ProfileBody(user: user),
      ),
    );
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NewPalette.background,
      shape: Border(top: BorderSide(color: NewPalette.border, width: 1.5)),
      builder: (_) => const _SettingsSheet(),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final WUser user;
  const _ProfileBody({required this.user});

  void _confirmRegeneratePseudonym(BuildContext context, WUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NewPalette.background,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: NewPalette.border)),
        title: const Text('New pseudonym?',
            style: TextStyle(
                fontFamily: 'Nunito',
                color: NewPalette.white,
                fontWeight: FontWeight.w800)),
        content: TextStyle(
                color: NewPalette.surfaceMuted,
                fontSize: 13,
                fontFamily: 'Nunito')
            .tText(
                'Your current pseudonym will be replaced with a new random one. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: NewPalette.white,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final rng = Random();
              final adj = AppConstants
                  .adjectives[rng.nextInt(AppConstants.adjectives.length)];
              final noun =
                  AppConstants.nouns[rng.nextInt(AppConstants.nouns.length)];
              final num = rng.nextInt(99) + 1;
              final newPseudo = '$adj$noun$num';
              await FirebaseFirestore.instance
                  .collection(AppConstants.usersCollection)
                  .doc(user.uid)
                  .update({'pseudonym': newPseudo});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('You are now $newPseudo 🎭',
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          color: NewPalette.background)),
                  backgroundColor: NewPalette.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NewPalette.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Regenerate',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    color: NewPalette.background)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteData(BuildContext context, WidgetRef ref, WUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NewPalette.background,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.redAccent)),
        title: const Text('Delete all data?',
            style: TextStyle(
                fontFamily: 'Nunito',
                color: Colors.redAccent,
                fontWeight: FontWeight.w800)),
        content: TextStyle(
                color: NewPalette.surfaceMuted,
                fontSize: 13,
                fontFamily: 'Nunito')
            .tText(
                'All your posts, comments, and account data will be permanently deleted. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: NewPalette.textMuted,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db = FirebaseFirestore.instance;
              final uid = user.uid;
              await db
                  .collection(AppConstants.usersCollection)
                  .doc(uid)
                  .update({
                'deleted': true,
                'deletedAt': FieldValue.serverTimestamp(),
              });
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/onboarding');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Delete Everything',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NewPalette.background,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: NewPalette.border)),
        title: const Text('Sign out?',
            style: TextStyle(
                fontFamily: 'Nunito',
                color: NewPalette.white,
                fontWeight: FontWeight.w800)),
        content: TextStyle(
                color: NewPalette.surfaceMuted,
                fontSize: 13,
                fontFamily: 'Nunito')
            .tText(
                'You\'ll lose access to your anonymous identity unless you\'ve linked an email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: NewPalette.textMuted,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/onboarding');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: NewPalette.cardBg,
                elevation: 0,
                side: BorderSide(color: NewPalette.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Sign Out',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: NewPalette.white,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showPremiumSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _PremiumSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communitiesAsync = ref.watch(communitiesStreamProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: NewPalette.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NewPalette.border),
            ),
            child: Column(
              children: [
                WAvatar(
                  pseudonym: user.pseudonym,
                  colorIndex: user.avatarColorIndex,
                  size: 76,
                  isPremium: user.isPremium,
                  showRing: true,
                ),
                const SizedBox(height: 14),
                Text(
                  user.pseudonym,
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: NewPalette.white,
                      letterSpacing: -0.4),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: NewPalette.primary),
                    ),
                    const SizedBox(width: 6),
                    const Text('Anonymous Status',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: NewPalette.primary,
                            fontWeight: FontWeight.w700)),
                    if (user.isPremium) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: NewPalette.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('✦ PREMIUM',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 9,
                                color: NewPalette.background,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _StatPill(label: 'Posts', value: '${user.postCount}'),
                    const SizedBox(width: 10),
                    _StatPill(
                      label: 'Member Since',
                      value: '${user.joinedAt.month}/${user.joinedAt.year}',
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 16),
          if (!user.isPremium)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NewPalette.primarySoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: NewPalette.primary.withOpacity(0.25), width: 1.5),
              ),
              child: Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Whispr Premium',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: NewPalette.white)),
                        const SizedBox(height: 2),
                        Text('No ads · 1k character limits · Badges',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                color: NewPalette.surfaceMuted)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showPremiumSheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NewPalette.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    child: const Text('\$3.99/mo',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: NewPalette.background)),
                  ),
                ],
              ),
            ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 20),
          const Text('Your Communities',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: NewPalette.white)),
          const SizedBox(height: 10),
          communitiesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: NewPalette.primary),
              ),
            ),
            error: (err, _) =>
                const _EmptySection(label: 'Failed to synchronize communities'),
            data: (allCommunitiesList) {
              // Normalize user joined strings to lowercase trimmed formats to prevent mismatch drops
              final userJoinedIds = user.joinedCommunities
                  .map((id) => id.trim().toLowerCase())
                  .toSet();

              // FIX: Case-insensitive lookups ensure custom user-created communities pass cleanly
              final joinedCommunitiesList = allCommunitiesList.where((c) {
                final String communityId =
                    (c['id'] as String? ?? '').trim().toLowerCase();
                return userJoinedIds.contains(communityId);
              }).toList();

              if (joinedCommunitiesList.isEmpty) {
                return const _EmptySection(
                    label: "You haven't joined any communities yet");
              }

              return Column(
                children: joinedCommunitiesList
                    .map((c) => _CommunityRow(data: c))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text('Account',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: NewPalette.white)),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.refresh_rounded,
            label: 'Regenerate pseudonym',
            color: NewPalette.primary,
            onTap: () => _confirmRegeneratePseudonym(context, user),
          ),
          _ActionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Delete all my data',
            color: Colors.redAccent,
            onTap: () => _confirmDeleteData(context, ref, user),
          ),
          _ActionTile(
            icon: Icons.logout_rounded,
            label: 'Sign out of profile',
            color: NewPalette.surfaceMuted,
            onTap: () => _confirmSignOut(context, ref),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: NewPalette.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NewPalette.border),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: NewPalette.primary)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: NewPalette.textMuted,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String label;
  const _EmptySection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NewPalette.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NewPalette.border),
      ),
      child: Text(label,
          style: TextStyle(
              fontFamily: 'Nunito', color: NewPalette.textMuted, fontSize: 13),
          textAlign: TextAlign.center),
    );
  }
}

class _CommunityRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CommunityRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = Color(data['color'] as int);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: NewPalette.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NewPalette.border),
      ),
      child: Row(
        children: [
          Text(data['icon'] as String? ?? '💬',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(data['name'] as String? ?? '',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      color: NewPalette.white))),
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: NewPalette.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NewPalette.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: color == NewPalette.surfaceMuted
                            ? NewPalette.white
                            : color,
                        fontWeight: FontWeight.w700))),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: NewPalette.textMuted.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                  color: NewPalette.border,
                  borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Settings',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: NewPalette.white)),
          const SizedBox(height: 16),
          _SettingsRow(
            icon: Icons.notifications_outlined,
            label: 'Push Notifications',
            trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeColor: NewPalette.primary),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: _SettingsRow(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              trailing: Icon(Icons.open_in_new,
                  size: 16, color: NewPalette.textMuted),
            ),
          ),
          _SettingsRow(
            icon: Icons.info_outline_rounded,
            label: 'App Version',
            trailing: Text('1.0.0',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: NewPalette.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  const _SettingsRow(
      {required this.icon, required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: NewPalette.surfaceMuted),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      color: NewPalette.white,
                      fontWeight: FontWeight.w600))),
          trailing,
        ],
      ),
    );
  }
}

class _PremiumSheet extends StatelessWidget {
  const _PremiumSheet();

  static const _perks = [
    (Icons.block_rounded, 'No advertisements completely'),
    (Icons.edit_note_rounded, '1,000 character whispers (vs 500)'),
    (Icons.rocket_launch_rounded, 'Boost 3 hot topics per month'),
    (Icons.palette_rounded, 'Custom avatar sets & identity themes'),
    (Icons.verified_rounded, 'Exclusive Premium ✦ badge'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 36,
      ),
      decoration: BoxDecoration(
        color: NewPalette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: NewPalette.border, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                  color: NewPalette.border,
                  borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NewPalette.primarySoft,
            ),
            child: const Text('✦',
                style: TextStyle(fontSize: 26, color: NewPalette.primary)),
          ),
          const SizedBox(height: 12),
          const Text('Whispr Premium',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: NewPalette.white)),
          const SizedBox(height: 4),
          TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: NewPalette.surfaceMuted)
              .tText('Support the community and unlock perks'),
          const SizedBox(height: 20),
          ..._perks.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: NewPalette.cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: NewPalette.border),
                      ),
                      child: Icon(p.$1, size: 16, color: NewPalette.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(p.$2,
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              color: NewPalette.white,
                              fontWeight: FontWeight.w700)),
                    ),
                    const Icon(Icons.check_rounded,
                        size: 16, color: NewPalette.primary),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _PriceButton(
                  label: 'Monthly Tier',
                  price: '\$3.99',
                  sub: 'per month',
                  isBest: false,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PriceButton(
                  label: 'Annual Plan',
                  price: '\$29.99',
                  sub: 'save 37%',
                  isBest: true,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Subscriptions auto-renew via system app store stores.\nCancel anytime in subscription profiles.',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                color: NewPalette.textMuted,
                height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PriceButton extends StatelessWidget {
  final String label;
  final String price;
  final String sub;
  final bool isBest;
  final VoidCallback onTap;

  const _PriceButton({
    required this.label,
    required this.price,
    required this.sub,
    required this.isBest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isBest ? NewPalette.primary : NewPalette.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isBest ? Colors.transparent : NewPalette.border),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: isBest
                      ? NewPalette.background.withOpacity(0.7)
                      : NewPalette.textMuted,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              price,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isBest ? NewPalette.background : NewPalette.white),
            ),
            Text(
              sub,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: isBest
                      ? NewPalette.background.withOpacity(0.8)
                      : NewPalette.primary,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

extension TextWrapper on TextStyle {
  Widget tText(String data) => Text(data, style: this);
}
