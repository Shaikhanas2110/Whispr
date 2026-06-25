import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../post/data/post_service.dart';
import '../../post/domain/post_model.dart';
import '../../post/presentation/post_card.dart';
import '../data/community_service.dart';
import '../../../app/constants.dart';

class NewPalette {
  static const Color primary = Color(0xFFA7ED10); // Vibrant Lime
  static const Color surfaceMuted = Color(0xFFB5B5B5); // Neutral Gray
  static const Color background = Color(0xFF000000); // Deep Black
  static const Color white = Color(0xFFFFFFFF); // Crisp White

  static final Color cardBg = surfaceMuted.withOpacity(0.12);
  static final Color border = surfaceMuted.withOpacity(0.25);
  static final Color primarySoft = primary.withOpacity(0.15);
  static final Color textMuted = surfaceMuted.withOpacity(0.7);
}

class CommunityDetailScreen extends ConsumerWidget {
  final String communityId;
  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Listen to real-time data streams
    final postsAsync = ref.watch(communityPostsStreamProvider(communityId));
    final joinedAsync = ref.watch(joinedCommunitiesProvider);
    final communitiesAsync = ref.watch(communitiesStreamProvider);

    final normalizedTargetId = communityId.trim().toLowerCase();
    final isJoined = joinedAsync.valueOrNull?.any(
          (id) => id.trim().toLowerCase() == normalizedTargetId,
        ) ??
        false;

    // 2. RESOLUTION: Dynamically look up meta profiles from the active Firestore stream
    final Map<String, dynamic> meta = communitiesAsync.maybeWhen(
      data: (list) => list.firstWhere(
        (c) => (c['id'] as String).trim().toLowerCase() == normalizedTargetId,
        orElse: () => {'name': communityId, 'icon': '💬', 'color': 0xFFB5B5B5},
      ),
      orElse: () => AppConstants.defaultCommunities.firstWhere(
        (c) => (c['id'] as String).trim().toLowerCase() == normalizedTargetId,
        orElse: () => {'name': communityId, 'icon': '💬', 'color': 0xFFB5B5B5},
      ),
    );

    final color = Color(meta['color'] as int);

    return Scaffold(
      backgroundColor: NewPalette.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // 1. Hero Header Sliver Block
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: NewPalette.background,
            elevation: 0,
            iconTheme: const IconThemeData(color: NewPalette.white),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
                child: GestureDetector(
                  onTap: () async {
                    final service = ref.read(communityServiceProvider);
                    if (isJoined) {
                      await service.leaveCommunity(communityId);
                    } else {
                      await service.joinCommunity(communityId);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isJoined ? Colors.transparent : NewPalette.primary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isJoined ? NewPalette.border : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      isJoined ? 'Joined' : 'Join',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color:
                            isJoined ? NewPalette.white : NewPalette.background,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                color: NewPalette.background,
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -10,
                      child: Text(
                        meta['icon'] as String? ??
                            '💬', // Shows live custom icon from stream
                        style: TextStyle(
                          fontSize: 130,
                          color: color.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 4, color: color),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 52, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: color.withOpacity(0.3), width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  meta['icon'] as String? ??
                                      '💬', // Shows live custom icon from stream
                                  style: const TextStyle(fontSize: 32),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              meta['name'] as String? ?? communityId,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: NewPalette.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Stream Resolution Pipeline
          postsAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: NewPalette.primary,
                ),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(
                      color: Colors.redAccent, fontFamily: 'Nunito'),
                ),
              ),
            ),
            data: (posts) => posts.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🫧',
                            style: TextStyle(
                                fontSize: 40, color: color.withOpacity(0.3)),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Be the first to share here!',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: NewPalette.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => PostCard(post: posts[i], index: i),
                        childCount: posts.length,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create?communityId=$communityId'),
        backgroundColor: NewPalette.primary,
        foregroundColor: NewPalette.background,
        elevation: 4,
        icon: const Icon(Icons.edit_rounded,
            color: NewPalette.background, size: 18),
        label: const Text('Post here',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
            )),
      ),
    );
  }
}

final communityPostsStreamProvider =
    StreamProvider.family<List<WPost>, String>((ref, id) {
  return Stream.periodic(const Duration(seconds: 4))
      .asyncMap((_) => ref.read(postServiceProvider).fetchCommunityPosts(id));
});
