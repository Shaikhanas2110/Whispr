import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../post/domain/post_model.dart';
import '../../../app/constants.dart';

enum FeedType { trending, newest, forYou }

final feedStreamProvider =
    StreamProvider.family<List<WPost>, FeedType>((ref, type) {
  final db = FirebaseFirestore.instance;
  Query<Map<String, dynamic>> q = db
      .collection(AppConstants.postsCollection)
      .where('status', isEqualTo: 'active')
      .limit(AppConstants.postsPerPage);

  switch (type) {
    case FeedType.trending:
      q = q
          .orderBy('trendScore', descending: true)
          .orderBy('createdAt', descending: true);
      break;
    case FeedType.newest:
    case FeedType.forYou:
      q = q.orderBy('createdAt', descending: true);
      break;
  }

  return q
      .snapshots()
      .map((snap) => snap.docs.map((d) => WPost.fromFirestore(d)).toList());
});

// ── Pagination state (load-more pages beyond page 1) ──────
class FeedState {
  final List<WPost> extra;
  final bool isLoadingMore;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;

  const FeedState({
    this.extra = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.lastDoc,
  });

  FeedState copyWith(
          {List<WPost>? extra,
          bool? isLoadingMore,
          bool? hasMore,
          DocumentSnapshot? lastDoc}) =>
      FeedState(
        extra: extra ?? this.extra,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        lastDoc: lastDoc ?? this.lastDoc,
      );
}

final feedPaginationProvider =
    StateNotifierProvider.family<FeedPaginationNotifier, FeedState, FeedType>(
  (ref, type) => FeedPaginationNotifier(type),
);

class FeedPaginationNotifier extends StateNotifier<FeedState> {
  final FeedType feedType;
  FeedPaginationNotifier(this.feedType) : super(const FeedState());

  final _db = FirebaseFirestore.instance;

  Future<void> loadMore(DocumentSnapshot? lastVisible) async {
    if (state.isLoadingMore || !state.hasMore || lastVisible == null) return;
    state = state.copyWith(isLoadingMore: true);

    try {
      Query<Map<String, dynamic>> q = _db
          .collection(AppConstants.postsCollection)
          .where('status', isEqualTo: 'active')
          .limit(AppConstants.postsPerPage);

      switch (feedType) {
        case FeedType.trending:
          q = q
              .orderBy('trendScore', descending: true)
              .orderBy('createdAt', descending: true);
          break;
        case FeedType.newest:
        case FeedType.forYou:
          q = q.orderBy('createdAt', descending: true);
          break;
      }

      final snap = await q.startAfterDocument(lastVisible).get();
      final newPosts = snap.docs.map((d) => WPost.fromFirestore(d)).toList();
      final rawLast = snap.docs.isNotEmpty ? snap.docs.last : null;

      state = state.copyWith(
        extra: [...state.extra, ...newPosts],
        isLoadingMore: false,
        hasMore: newPosts.length == AppConstants.postsPerPage,
        lastDoc: rawLast,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void reset() => state = const FeedState();
}
