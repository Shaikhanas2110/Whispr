import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../data/feed_provider.dart';
import '../../post/presentation/post_card.dart';
import '../../../app/constants.dart';

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

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});
  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _tabs = [FeedType.trending, FeedType.newest, FeedType.forYou];
  final _labels = ['Trending', 'New', 'For You'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _openSearch() => context.push('/search');

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NewPalette.background,
      shape: Border(
        top: BorderSide(color: NewPalette.border, width: 1.5),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: NewPalette.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: NewPalette.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.filter_list_rounded,
                      color: NewPalette.primary, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Browse Communities',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: NewPalette.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.defaultCommunities.map((c) {
                final color = Color(c['color'] as int);
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/community/${c['id']}');
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: color.withOpacity(0.3), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c['icon'] as String,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          c['name'] as String,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: NewPalette.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // 1. Smooth Floating Top App Bar
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false, // Allows the main identity bar to hide smoothly
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
                        text: const TextSpan(
                          text: 'w',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: NewPalette.primary,
                            letterSpacing: -0.5,
                          ),
                          children: [
                            TextSpan(
                              text: 'hispr',
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
                          'A N O N Y M O U S',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            color: NewPalette.white.withOpacity(0.35),
                            letterSpacing: 1.8,
                            height: 0.9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                GestureDetector(
                  onTap: _openSearch,
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: NewPalette.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: NewPalette.border),
                    ),
                    child: const Icon(Icons.search, color: NewPalette.white),
                  ),
                ),
                GestureDetector(
                  onTap: _openFilter,
                  child: Container(
                    margin: const EdgeInsets.only(right: 14),
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: NewPalette.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: NewPalette.border),
                    ),
                    child: const Icon(Icons.tune_rounded,
                        color: NewPalette.white, size: 20),
                  ),
                ),
              ],
            ),

            // 2. Lag-Free Pinned TabBar Header (Stays pinned to the top)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                child: Container(
                  color: NewPalette.background,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(height: 1, color: NewPalette.border),
                      const SizedBox(height: 5),
                      TabBar(
                        controller: _tab,
                        tabs: _labels
                            .map((t) => Tab(
                                child: Text(t,
                                    style: const TextStyle(fontSize: 13))))
                            .toList(),
                        labelColor: NewPalette.primary,
                        unselectedLabelColor: NewPalette.textMuted,
                        labelStyle: const TextStyle(
                            fontFamily: 'Nunito', fontWeight: FontWeight.w800),
                        unselectedLabelStyle: const TextStyle(
                            fontFamily: 'Nunito', fontWeight: FontWeight.w500),
                        indicator: BoxDecoration(
                          color: NewPalette.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: NewPalette.primary.withOpacity(0.3),
                              width: 1),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        dividerColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Keep the body inside a view window or use full list mapping directly
            SliverFillRemaining(
              child: TabBarView(
                controller: _tab,
                physics: const BouncingScrollPhysics(),
                children: _tabs.map((t) => _FeedList(feedType: t)).toList(),
              ),
            ),
          ],
        ));
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverTabBarDelegate({required this.child});

  @override
  // Height of your customized tab bar layout container segment
  double get minExtent => 65;
  @override
  double get maxExtent => 65;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

// ── Feed list ──────────────────────────────────────────────────
class _FeedList extends ConsumerStatefulWidget {
  final FeedType feedType;
  const _FeedList({required this.feedType});

  @override
  ConsumerState<_FeedList> createState() => _FeedListState();
}

class _FeedListState extends ConsumerState<_FeedList>
    with AutomaticKeepAliveClientMixin {
  final _scrollCtrl = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      ref.read(feedPaginationProvider(widget.feedType).notifier).loadMore(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final streamAsync = ref.watch(feedStreamProvider(widget.feedType));
    final pagination = ref.watch(feedPaginationProvider(widget.feedType));

    return streamAsync.when(
      loading: () => const _ShimmerFeed(),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.redAccent))),
      data: (livePosts) {
        final all = [...livePosts, ...pagination.extra];
        if (all.isEmpty) return const _EmptyState();

        return RefreshIndicator(
          color: NewPalette.primary,
          backgroundColor: NewPalette.background,
          onRefresh: () async {
            ref.read(feedPaginationProvider(widget.feedType).notifier).reset();
            ref.invalidate(feedStreamProvider(widget.feedType));
          },
          child: ListView.builder(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            cacheExtent: 500,
            addAutomaticKeepAlives: true,
            addRepaintBoundaries: true,
            padding: const EdgeInsets.only(top: 10, bottom: 100),
            itemCount: all.length + (pagination.isLoadingMore ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == all.length) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: NewPalette.primary)),
                );
              }
              return RepaintBoundary(
                child: PostCard(post: all[i], index: i),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Shimmer skeleton ───────────────────────────────────────────
class _ShimmerFeed extends StatelessWidget {
  const _ShimmerFeed();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 10),
      itemCount: 4,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        height: 150,
        decoration: BoxDecoration(
          color: NewPalette.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NewPalette.border),
        ),
      ).animate(delay: Duration(milliseconds: i * 80)).shimmer(
            duration: 1300.ms,
            color: NewPalette.surfaceMuted.withOpacity(0.15),
          ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
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
                  color: NewPalette.primary.withOpacity(0.2), width: 2),
            ),
            child:
                const Center(child: Text('🫧', style: TextStyle(fontSize: 48))),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.08, 1.08),
              duration: 2.seconds),
          const SizedBox(height: 22),
          const Text(
            'Nothing here yet',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: NewPalette.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to whispr something!',
            style: TextStyle(fontSize: 13, color: NewPalette.surfaceMuted),
          ),
        ],
      ),
    );
  }
}
