import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';
import '../../post/data/post_service.dart';
import '../../post/domain/post_model.dart';
import '../../auth/data/auth_service.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../../../shared/widgets/w_avatar.dart';
import '../../../app/constants.dart';
import 'package:share_plus/share_plus.dart';

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

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});
  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  String? _replyingToId;
  String? _replyingToPseudonym;

  final Set<String> _likedComments = {};
  final Map<String, int> _likeCountOverrides = {};

  void _setReply(String commentId, String pseudonym) {
    setState(() {
      _replyingToId = commentId;
      _replyingToPseudonym = pseudonym;
    });
  }

  void _clearReply() {
    setState(() {
      _replyingToId = null;
      _replyingToPseudonym = null;
    });
  }

  Future<void> _toggleLike(WComment comment) async {
    final alreadyLiked = _likedComments.contains(comment.id);
    setState(() {
      if (alreadyLiked) {
        _likedComments.remove(comment.id);
        final rawCount =
            (_likeCountOverrides[comment.id] ?? comment.likeCount) - 1;
        // FIX: Clamp execution limits to eliminate negative counter boundaries completely
        _likeCountOverrides[comment.id] = rawCount.clamp(0, 999999);
      } else {
        _likedComments.add(comment.id);
        _likeCountOverrides[comment.id] =
            (_likeCountOverrides[comment.id] ?? comment.likeCount) + 1;
      }
    });
    try {
      await ref.read(postServiceProvider).likeComment(comment.id);
    } catch (_) {
      setState(() {
        if (alreadyLiked) {
          _likedComments.add(comment.id);
          _likeCountOverrides[comment.id] =
              (_likeCountOverrides[comment.id] ?? comment.likeCount) + 1;
        } else {
          _likedComments.remove(comment.id);
          final rawCount =
              (_likeCountOverrides[comment.id] ?? comment.likeCount) - 1;
          _likeCountOverrides[comment.id] = rawCount.clamp(0, 999999);
        }
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final user = await ref.read(authServiceProvider).signInAnonymously();
      await ref.read(postServiceProvider).addComment(
            author: user,
            postId: widget.postId,
            content: text,
            parentId: _replyingToId,
          );
      _commentCtrl.clear();
      _clearReply();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(_postDetailProvider(widget.postId));
    final commentsStream = ref.watch(_commentsProvider(widget.postId));

    return Scaffold(
      backgroundColor: NewPalette.background,
      appBar: AppBar(
        backgroundColor: NewPalette.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: NewPalette.white),
        title: const Text('Whispr',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                color: NewPalette.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: NewPalette.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: NewPalette.white),
            onPressed: () async {
              final post =
                  ref.read(_postDetailProvider(widget.postId)).valueOrNull;
              if (post != null) {
                final url = 'https://whispr.app/post/${post.id}';
                final preview = post.content.length > 100
                    ? '${post.content.substring(0, 100)}…'
                    : post.content;
                await Share.share('$preview\n\n$url',
                    subject: 'Check this Whispr');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.redAccent),
            onPressed: () => showReportSheet(context, widget.postId),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: postAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: NewPalette.primary)),
                    ),
                    error: (e, _) => Center(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Error: $e',
                                style:
                                    const TextStyle(color: Colors.redAccent)))),
                    data: (post) => (post == null)
                        ? const Center(
                            child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text('Post not found',
                                    style: TextStyle(color: NewPalette.white))))
                        : _PostDetailBody(post: post),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    color: NewPalette.background,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: NewPalette.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 14, color: NewPalette.primary),
                        ),
                        const SizedBox(width: 10),
                        commentsStream.when(
                          loading: () => const Text('Comments',
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                  color: NewPalette.white)),
                          error: (_, __) => const Text('Comments',
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                  color: NewPalette.white)),
                          data: (c) => Text(
                            '${c.length} Total Comments',
                            style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: NewPalette.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                    child: Container(height: 1, color: NewPalette.border)),
                commentsStream.when(
                  loading: () => const SliverToBoxAdapter(
                      child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: NewPalette.primary)))),
                  error: (e, _) => SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Error: $e',
                              style:
                                  const TextStyle(color: Colors.redAccent)))),
                  data: (rawComments) {
                    final comments = List<WComment>.from(rawComments);

                    // FIX: Process replies using deep recursion map definitions
                    final parentToChildrenMap = <String, List<WComment>>{};
                    final topLevel = <WComment>[];

                    for (final c in comments) {
                      if (c.parentId == null || c.parentId!.isEmpty) {
                        topLevel.add(c);
                      } else {
                        parentToChildrenMap
                            .putIfAbsent(c.parentId!, () => [])
                            .add(c);
                      }
                    }

                    topLevel.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    for (final key in parentToChildrenMap.keys) {
                      parentToChildrenMap[key]!
                          .sort((a, b) => a.createdAt.compareTo(b.createdAt));
                    }

                    final flatList = <_FlatCommentItem>[];

                    // Recursive builder engine to map any level of nested replies
                    void addSubTree(
                        String parentId, int rootIndex, int currentDepth) {
                      final directReplies = parentToChildrenMap[parentId] ?? [];
                      for (final reply in directReplies) {
                        flatList.add(_FlatCommentItem(
                          comment: reply,
                          isReply: true,
                          rootIndex: rootIndex,
                          indentationLevel: currentDepth,
                        ));
                        // Cascade down deeper execution chains recursively
                        addSubTree(reply.id, rootIndex, currentDepth + 1);
                      }
                    }

                    for (int i = 0; i < topLevel.length; i++) {
                      final topComment = topLevel[i];
                      flatList.add(_FlatCommentItem(
                          comment: topComment, isReply: false, rootIndex: i));
                      addSubTree(topComment.id, i, 1);
                    }

                    if (flatList.isEmpty) {
                      return const SliverToBoxAdapter(
                          child: _EmptyCommentsPlaceholder());
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, index) {
                          final item = flatList[index];
                          final isLiked =
                              _likedComments.contains(item.comment.id);
                          final displayCount =
                              _likeCountOverrides[item.comment.id] ??
                                  item.comment.likeCount;
                          return _RenderedCommentNode(
                            item: item,
                            isLiked: isLiked,
                            displayLikeCount: displayCount,
                            onReply: (id, p) => _setReply(id, p),
                            onLike: () => _toggleLike(item.comment),
                          );
                        },
                        childCount: flatList.length,
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
          if (_replyingToPseudonym != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: NewPalette.primarySoft,
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded,
                      size: 14, color: NewPalette.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Replying to $_replyingToPseudonym',
                    style: const TextStyle(
                        fontSize: 12,
                        color: NewPalette.primary,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito'),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _clearReply,
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: NewPalette.primary),
                  ),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.only(
              left: 14,
              right: 12,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 10,
            ),
            decoration: BoxDecoration(
              color: NewPalette.background,
              border: Border(top: BorderSide(color: NewPalette.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    style:
                        const TextStyle(fontSize: 14, color: NewPalette.white),
                    decoration: InputDecoration(
                      hintText: _replyingToPseudonym != null
                          ? 'Reply to $_replyingToPseudonym…'
                          : 'Add a comment…',
                      hintStyle: TextStyle(color: NewPalette.textMuted),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      isDense: true,
                      filled: true,
                      fillColor: NewPalette.cardBg,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: NewPalette.border)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: NewPalette.primary, width: 1.5),
                      ),
                    ),
                    maxLength: 300,
                    buildCounter: (_,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        null,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submitting ? null : _submitComment,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: NewPalette.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _submitting
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: NewPalette.background))
                        : const Icon(Icons.send_rounded,
                            color: NewPalette.background, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlatCommentItem {
  final WComment comment;
  final bool isReply;
  final int rootIndex;
  final int indentationLevel; // Added structural indentation trackers

  const _FlatCommentItem({
    required this.comment,
    required this.isReply,
    required this.rootIndex,
    this.indentationLevel = 0,
  });
}


class _RenderedCommentNode extends StatelessWidget {
  final _FlatCommentItem item;
  final void Function(String, String) onReply;
  final bool isLiked;
  final int displayLikeCount;
  final VoidCallback onLike;

  const _RenderedCommentNode({
    required this.item,
    required this.onReply,
    required this.isLiked,
    required this.displayLikeCount,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final comment = item.comment;

    // Instagram Style: Dynamic metrics based on tree level depth
    final bool isNestedReply = item.indentationLevel > 0;
    final double leftPaddingOffset = isNestedReply
        ? (24.0 + (item.indentationLevel - 1) * 16.0).clamp(0.0, 64.0)
        : 0.0;
    final double avatarSize = isNestedReply ? 24.0 : 32.0;

    return Padding(
      padding: EdgeInsets.only(
          left: 16.0 + leftPaddingOffset, right: 16.0, top: 10.0, bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  WAvatar(
                    pseudonym: comment.authorPseudonym,
                    colorIndex: comment.authorColorIndex,
                    size: avatarSize,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          comment.authorPseudonym,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: isNestedReply ? 12.0 : 13.0,
                            fontWeight: FontWeight.w800,
                            color: NewPalette.white,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeago.format(comment.createdAt, locale: 'en_short'),
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10.5,
                            color: NewPalette.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      comment.content,
                      style: TextStyle(
                        fontSize: isNestedReply ? 12.5 : 13.5,
                        color: NewPalette.white.withOpacity(0.95),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              onReply(comment.id, comment.authorPseudonym),
                          child: Text(
                            'Reply',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11.0,
                              color: NewPalette.textMuted,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        if (displayLikeCount > 0) ...[
                          const SizedBox(width: 16),
                          Text(
                            '$displayLikeCount ${displayLikeCount == 1 ? 'like' : 'likes'}',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11.0,
                              color: NewPalette.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onLike,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                  child: Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 13.5,
                    color: isLiked ? Colors.redAccent : NewPalette.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Micro Divider Line tracking nested levels cleanly
          if (!isNestedReply)
            Padding(
              padding: const EdgeInsets.only(left: 44.0, top: 4.0),
              child: Container(
                  height: 0.5, color: NewPalette.border.withOpacity(0.12)),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 180.ms)
        .slideY(begin: 0.02, end: 0, curve: Curves.easeOut);
  }
}

class _PostDetailBody extends StatelessWidget {
  final WPost post;
  const _PostDetailBody({required this.post});

  @override
  Widget build(BuildContext context) {
    final commData = AppConstants.defaultCommunities.firstWhere(
      (c) => c['name'] == post.communityName,
      orElse: () => {'color': 0xFFBF6B3D, 'icon': '💬'},
    );
    final commColor = Color(commData['color'] as int);

    return Container(
      color: NewPalette.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 4, color: commColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: commColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: commColor.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          Text(commData['icon'] as String,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Text(post.communityName,
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  color: commColor,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('• ${timeago.format(post.createdAt)}',
                        style: TextStyle(
                            fontSize: 11, color: NewPalette.textMuted)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: commColor.withOpacity(0.5), width: 1.5)),
                      child: WAvatar(
                          pseudonym: post.authorPseudonym,
                          colorIndex: post.authorColorIndex,
                          size: 36,
                          isPremium: post.authorIsPremium),
                    ),
                    const SizedBox(width: 10),
                    Text(post.authorPseudonym,
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: NewPalette.white)),
                    if (post.authorIsPremium) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: NewPalette.primary,
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('✦ PRO',
                            style: TextStyle(
                                fontSize: 9,
                                color: NewPalette.background,
                                fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Text(post.content,
                    style: const TextStyle(
                        fontSize: 15, color: NewPalette.white, height: 1.6)),
                const SizedBox(height: 16),
                if (post.reactions.values.any((v) => v > 0)) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.reactions.entries.map((e) {
                      final count = post.reactions[e.key] ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: NewPalette.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: NewPalette.border)),
                        child: Text('${e.value} $count',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: NewPalette.white)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 14, color: NewPalette.textMuted),
                    const SizedBox(width: 4),
                    Text('${post.commentCount} comments',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: NewPalette.textMuted,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCommentsPlaceholder extends StatelessWidget {
  const _EmptyCommentsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: NewPalette.primarySoft, shape: BoxShape.circle),
            child:
                const Center(child: Text('💬', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(height: 14),
          const Text('No comments yet',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: NewPalette.white)),
          const SizedBox(height: 4),
          Text('Be the first to reply!',
              style: TextStyle(fontSize: 13, color: NewPalette.textMuted)),
        ],
      ),
    );
  }
}

final _postDetailProvider = FutureProvider.family<WPost?, String>((ref, id) {
  return ref.watch(postServiceProvider).fetchPost(id);
});

final _commentsProvider =
    StreamProvider.family<List<WComment>, String>((ref, id) {
  return ref.watch(postServiceProvider).commentsStream(id);
});
