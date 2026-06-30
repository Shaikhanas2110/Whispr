import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../post/data/post_service.dart';
import '../../post/domain/post_model.dart';
import 'sparks_card.dart';
import '../data/sparks_video_cache.dart';

class NewPalette {
  static const Color primary = Color(0xFFA7ED10);
  static const Color background = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static final Color textMuted = white.withOpacity(0.7);
}

class ReelsState {
  final List<WPost> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
  final String? error;

  const ReelsState({
    this.posts = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.lastDoc,
    this.error,
  });

  ReelsState copyWith({
    List<WPost>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    String? error,
    bool clearError = false,
  }) =>
      ReelsState(
        posts: posts ?? this.posts,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        lastDoc: lastDoc ?? this.lastDoc,
        error: clearError ? null : (error ?? this.error),
      );
}

class ReelsNotifier extends StateNotifier<ReelsState> {
  final PostService _service;
  StreamSubscription<List<WPost>>? _sub;

  List<WPost> _extraPosts = [];

  ReelsNotifier(this._service) : super(const ReelsState()) {
    _subscribe();
  }

  void _subscribe() {
    state = state.copyWith(isLoading: true, clearError: true);
    _sub?.cancel();
    _sub = _service.streamVideoPosts().listen(
      (livePosts) {
        final posts = [...livePosts, ..._extraPosts];
        state = state.copyWith(
          posts: posts,
          isLoading: false,
          hasMore: true,
          clearError: true,
        );
      },
      onError: (e, st) {
        debugPrint('REELS LOAD ERROR: $e');
        if (st is StackTrace) debugPrintStack(stackTrace: st);
        state = state.copyWith(
          isLoading: false,
          hasMore: false,
          error: e.toString(),
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.posts.isEmpty) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _service.fetchVideoPosts(lastDoc: state.lastDoc);
      final more = page.posts.where((p) => p.hasVideo).toList();
      _extraPosts = [..._extraPosts, ...more];
      state = state.copyWith(
        posts: [...state.posts, ...more],
        isLoadingMore: false,
        hasMore: page.posts.isNotEmpty,
        lastDoc: page.lastDoc ?? state.lastDoc,
      );
    } catch (e) {
      debugPrint('REELS LOAD MORE ERROR: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    _extraPosts = [];
    state = const ReelsState();
    _subscribe();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final reelsProvider =
    StateNotifierProvider.autoDispose<ReelsNotifier, ReelsState>((ref) {
  return ReelsNotifier(ref.read(postServiceProvider));
});

// ---------------------------------------------------------------------------
// ReelsScreen
// ---------------------------------------------------------------------------
class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  // Shared controller cache for the whole feed — survives across page
  // changes so preloaded reels don't get thrown away on every rebuild.
  final ReelVideoCache _videoCache = ReelVideoCache();

  // How many reels ahead of the current one to keep preloaded. 2 mirrors
  // Instagram's behavior closely without preloading too aggressively on
  // slow connections.
  static const int _preloadAhead = 2;
  static const int _keepBehind = 1;

  String? _lastPreloadedPostsSignature;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _videoCache.disposeAll();
    super.dispose();
  }

  void _onPageChanged(int index, List<WPost> posts) {
    setState(() => _currentPage = index);
    if (index >= posts.length - 2) {
      ref.read(reelsProvider.notifier).loadMore();
    }
    _updatePreloadWindow(index, posts);
  }

  /// Preloads the next [_preloadAhead] reels and frees controllers outside
  /// the [_keepBehind, index + _preloadAhead] window so the cache doesn't
  /// grow unbounded as the user scrolls through a long session.
  void _updatePreloadWindow(int index, List<WPost> posts) {
    if (posts.isEmpty) return;

    final keepIds = <String>{};
    for (var i = index - _keepBehind; i <= index + _preloadAhead; i++) {
      if (i < 0 || i >= posts.length) continue;
      keepIds.add(posts[i].id);
      if (i >= index) {
        // Preload current + upcoming reels.
        _videoCache.preload(posts[i]);
      }
    }
    _videoCache.disposeExcept(keepIds);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reelsProvider);

    // Whenever the post list changes (initial load, live updates, loadMore),
    // re-run the preload window so newly-arrived reels at the front/back
    // get preloaded too. Guarded by a cheap signature so this doesn't fire
    // redundantly on every rebuild.
    final signature = state.posts.map((p) => p.id).join(',');
    if (signature != _lastPreloadedPostsSignature) {
      _lastPreloadedPostsSignature = signature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updatePreloadWindow(_currentPage, state.posts);
      });
    }

    return Scaffold(
      backgroundColor: NewPalette.background,
      body: Stack(
        children: [
          if (state.isLoading)
            const Center(
              child: CircularProgressIndicator(color: NewPalette.primary),
            )
          else if (state.error != null)
            _ReelsErrorState(
              message: state.error!,
              onRetry: () => ref.read(reelsProvider.notifier).refresh(),
            )
          else if (state.posts.isEmpty)
            const _EmptyReels()
          else
            RefreshIndicator(
              color: NewPalette.primary,
              backgroundColor: NewPalette.background,
              onRefresh: () => ref.read(reelsProvider.notifier).refresh(),
              child: PageView.builder(
                controller: _pageCtrl,
                scrollDirection: Axis.vertical,
                itemCount: state.posts.length,
                onPageChanged: (i) => _onPageChanged(i, state.posts),
                itemBuilder: (ctx, i) {
                  final post = state.posts[i];
                  return ReelCard(
                    key: ValueKey(post.id),
                    post: post,
                    isActive: i == _currentPage,
                    cache: _videoCache,
                  );
                },
              ),
            ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: NewPalette.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Sparks',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
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
    );
  }
}

class _ReelsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ReelsErrorState({required this.message, required this.onRetry});

  bool get _looksLikeMissingIndex =>
      message.toLowerCase().contains('failed-precondition') ||
      message.toLowerCase().contains('requires an index');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 40),
            const SizedBox(height: 14),
            Text(
              _looksLikeMissingIndex
                  ? 'Firestore needs an index for this query'
                  : 'Could not load reels',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: NewPalette.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _looksLikeMissingIndex
                  ? 'Open the debug console — Firestore prints a direct link to auto-create the missing index (status + hasVideo + createdAt).'
                  : message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: NewPalette.textMuted),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: NewPalette.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    color: NewPalette.background,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReels extends StatelessWidget {
  const _EmptyReels();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎬', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'No sparks yet',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: NewPalette.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Post a video to start the feed!',
            style: TextStyle(fontSize: 13, color: NewPalette.textMuted),
          ),
        ],
      ),
    );
  }
}
