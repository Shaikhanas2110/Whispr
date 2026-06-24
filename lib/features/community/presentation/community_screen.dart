import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/community_service.dart';

class NewPalette {
  static const Color primary = Color(0xFFA7ED10);
  static const Color surfaceMuted = Color(0xFFB5B5B5);
  static const Color background = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static final Color cardBg = white.withOpacity(0.03);
  static final Color border = white.withOpacity(0.08);
  static final Color primarySoft = primary.withOpacity(0.12);
  static final Color textMuted = white.withOpacity(0.45);
}

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  String _query = '';

  void _showCreateCommunitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NewPalette.background,
      shape: Border(top: BorderSide(color: NewPalette.border, width: 1.5)),
      builder: (ctx) => const _CreateCommunityModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final communitiesAsync = ref.watch(communitiesStreamProvider);

    return Scaffold(
      backgroundColor: NewPalette.background,
      body: Stack(
        children: [
          // Background Top Corner Gradient Mesh Pop
          Positioned(
            top: -80,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    NewPalette.primary.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          communitiesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                  color: NewPalette.primary, strokeWidth: 2),
            ),
            error: (err, _) => Center(
              child: Text('Error loading tribes: $err',
                  style: const TextStyle(
                      color: Colors.redAccent,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold)),
            ),
            data: (communitiesList) {
              final filtered = communitiesList.where((c) {
                if (_query.trim().isEmpty) return true;
                return (c['name'] as String)
                    .toLowerCase()
                    .contains(_query.toLowerCase());
              }).toList();

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: NewPalette.background.withOpacity(0.85),
                    elevation: 0,
                    titleSpacing: 20,
                    expandedHeight: 76,
                    toolbarHeight: 70,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: const TextSpan(
                            text: 'C',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: NewPalette.primary,
                              letterSpacing: -0.5,
                            ),
                            children: [
                              TextSpan(
                                text: 'ommunities',
                                style: TextStyle(
                                  color: NewPalette.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'D I S C O V E R  T R I B E S',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: NewPalette.textMuted,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(64),
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          style: const TextStyle(
                              fontSize: 14,
                              color: NewPalette.white,
                              fontFamily: 'Nunito'),
                          cursorColor: NewPalette.primary,
                          decoration: InputDecoration(
                            hintText: 'Search communities...',
                            hintStyle: TextStyle(
                                color: NewPalette.textMuted,
                                fontSize: 13,
                                fontFamily: 'Nunito'),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: NewPalette.textMuted, size: 18),
                            suffixIcon: _query.isNotEmpty
                                ? GestureDetector(
                                    onTap: () => setState(() => _query = ''),
                                    child: Icon(Icons.clear_rounded,
                                        size: 16, color: NewPalette.textMuted),
                                  )
                                : null,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                            isDense: true,
                            filled: true,
                            fillColor: NewPalette.white.withOpacity(0.03),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: NewPalette.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: NewPalette.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: NewPalette.primary, width: 1.2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🫧', style: TextStyle(fontSize: 40)),
                            SizedBox(height: 12),
                            Text('No communities found',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: NewPalette.surfaceMuted,
                                )),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Text(
                          'EXPLORE ALL',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: NewPalette.textMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.02,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _CommunityCard(
                              data: filtered[index], index: index),
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCommunitySheet(context),
        backgroundColor: NewPalette.primary,
        foregroundColor: NewPalette.background,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: const Icon(Icons.add_circle_outline_rounded,
            color: NewPalette.background, size: 18),
        label: const Text(
          'Create Tribe',
          style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.1),
        ),
      ),
    );
  }
}

class _CreateCommunityModal extends ConsumerStatefulWidget {
  const _CreateCommunityModal();

  @override
  ConsumerState<_CreateCommunityModal> createState() =>
      _CreateCommunityModalState();
}

class _CreateCommunityModalState extends ConsumerState<_CreateCommunityModal> {
  final _nameCtrl = TextEditingController();
  String _selectedIcon = '🫧';
  int _selectedColorValue = 0xFFA7ED10;

  final List<String> _emojis = [
    '🫧',
    '⚽',
    '🔥',
    '🎮',
    '💡',
    '🎵',
    '🍿',
    '🦊',
    '🎨',
    '🚀',
    '💔',
    '🤫'
  ];
  final List<int> _colors = [
    0xFFA7ED10,
    0xFFFF453A,
    0xFF30D158,
    0xFF0A84FF,
    0xFFBF5AF2,
    0xFFFF9F0A
  ];

  void _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final newCommunity = {
      'id': name.toLowerCase().replaceAll(' ', '_'),
      'name': name,
      'icon': _selectedIcon,
      'color': _selectedColorValue,
      'members': 1,
    };

    try {
      await ref
          .read(communityServiceProvider)
          .saveCustomCommunity(newCommunity);
      await ref
          .read(communityServiceProvider)
          .joinCommunity(newCommunity['id'] as String);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to establish tribe: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: NewPalette.border,
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Launch New Tribe',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: NewPalette.white),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(_selectedColorValue).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Color(_selectedColorValue).withOpacity(0.25),
                      width: 1.5),
                ),
                child: Center(
                    child: Text(_selectedIcon,
                        style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(
                      fontSize: 14,
                      color: NewPalette.white,
                      fontFamily: 'Nunito'),
                  autofocus: true,
                  maxLength: 24,
                  buildCounter: (_,
                          {required currentLength,
                          maxLength,
                          required isFocused}) =>
                      null,
                  cursorColor: NewPalette.primary,
                  decoration: InputDecoration(
                    hintText: 'Tribe name...',
                    hintStyle: TextStyle(
                        color: NewPalette.textMuted,
                        fontSize: 14,
                        fontFamily: 'Nunito'),
                    filled: true,
                    fillColor: NewPalette.white.withOpacity(0.02),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: NewPalette.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: NewPalette.border)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: NewPalette.primary, width: 1.2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Choose Token Badge',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: NewPalette.surfaceMuted,
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _emojis.length,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => setState(() => _selectedIcon = _emojis[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  width: 40,
                  decoration: BoxDecoration(
                    color: _selectedIcon == _emojis[i]
                        ? NewPalette.white.withOpacity(0.06)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedIcon == _emojis[i]
                          ? NewPalette.primary
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Center(
                      child: Text(_emojis[i],
                          style: const TextStyle(fontSize: 18))),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Choose Identity Color',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: NewPalette.surfaceMuted,
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => setState(() => _selectedColorValue = _colors[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 14),
                  width: 32,
                  decoration: BoxDecoration(
                    color: Color(_colors[i]),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColorValue == _colors[i]
                          ? NewPalette.white
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: _submit,
            child: Container(
              width: double.infinity,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: NewPalette.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Establish Community',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: NewPalette.background,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityCard extends ConsumerWidget {
  final Map<String, dynamic> data;
  final int index;
  const _CommunityCard({required this.data, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String communityId = data['id'] as String;
    final color = Color(data['color'] as int);

    final joinedAsync = ref.watch(joinedCommunitiesProvider);
    final isJoined = joinedAsync.valueOrNull?.contains(communityId) ?? false;

    final int baseMembers = data['members'] as int? ?? 0;
    final int realMembers = isJoined ? baseMembers + 1 : baseMembers;

    final membersStr = realMembers >= 1000
        ? '${(realMembers / 1000).toStringAsFixed(1)}k'
        : '$realMembers';

    return GestureDetector(
      onTap: () => context.push('/community/$communityId'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          // Pure Glassmorphism: Semi-translucent surface shifted dynamically based on joined state
          color: isJoined
              ? color.withOpacity(0.06)
              : NewPalette.white.withOpacity(0.02),
          borderRadius:
              BorderRadius.circular(24), // Sleek, smooth rounded corners
          border: Border.all(
            // Specular Highlight Border Effect
            color: isJoined
                ? color.withOpacity(0.35)
                : NewPalette.white.withOpacity(0.06),
            width: isJoined ? 1.5 : 1.0,
          ),
          boxShadow: [
            // Ambient micro shadow for depth separation
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Glass Token Badge Icon Component
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: color.withOpacity(0.18),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Text(
                    data['icon'] as String? ?? '💬',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),

              const Spacer(),

              // Typography Hierarchy Content Matrix
              Text(
                data['name'] as String? ?? '',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  color: NewPalette.white,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Dynamic Membership Identity Indicator Dot
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isJoined
                          ? NewPalette.primary
                          : color.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    membersStr,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: isJoined ? NewPalette.primary : NewPalette.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'whisperers',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: NewPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
