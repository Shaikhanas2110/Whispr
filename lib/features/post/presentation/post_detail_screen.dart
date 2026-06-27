import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:giphy_get/giphy_get.dart';
import '../../post/data/post_service.dart';
import '../../post/domain/post_model.dart';
import '../../auth/data/auth_service.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../../../shared/widgets/w_avatar.dart';
import '../../../app/constants.dart';
import 'package:share_plus/share_plus.dart';

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

// ---------------------------------------------------------------------------
// PostDetailScreen
// ---------------------------------------------------------------------------
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
  String? _commentGifUrl; // <-- NEW: GIF attached to the pending comment

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

  Future<void> _pickCommentGif() async {
    final gif = await GiphyGet.getGif(
      context: context,
      apiKey: 'xgoOqu43FnGUA7Rn9PMZOFZTjLU3XUPS',
      lang: GiphyLanguage.english,
      tabColor: NewPalette.primary,
    );
    if (gif != null && gif.images?.original?.webp != null) {
      setState(() => _commentGifUrl = gif.images!.original!.webp!);
    }
  }

  Future<void> _toggleLike(WComment comment) async {
    final alreadyLiked = _likedComments.contains(comment.id);
    setState(() {
      if (alreadyLiked) {
        _likedComments.remove(comment.id);
        final rawCount =
            (_likeCountOverrides[comment.id] ?? comment.likeCount) - 1;
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
    // Allow posting GIF-only comment (empty text is fine if GIF exists)
    if (text.isEmpty && _commentGifUrl == null) return;
    setState(() => _submitting = true);
    try {
      final user = await ref.read(authServiceProvider).signInAnonymously();
      await ref.read(postServiceProvider).addComment(
            author: user,
            postId: widget.postId,
            content: text,
            parentId: _replyingToId,
            gifUrl: _commentGifUrl, // <-- pass GIF
          );
      _commentCtrl.clear();
      setState(() => _commentGifUrl = null);
      _clearReply();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _confirmDeletePost(BuildContext context, WPost post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NewPalette.background,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.redAccent, width: 1)),
        title: const Text('Delete Whisper?',
            style: TextStyle(
                fontFamily: 'Nunito',
                color: Colors.white,
                fontWeight: FontWeight.w900)),
        content: const Text(
            'This action removes the post permanently from everyone\'s feed views. This cannot be reversed.',
            style: TextStyle(
                fontFamily: 'Nunito', color: NewPalette.white, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white60,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(postServiceProvider)
                    .deletePost(post.id, post.authorId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Post deleted successfully 🗑️',
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                              color: NewPalette.background)),
                      backgroundColor: NewPalette.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed to delete post: $e'),
                        backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
        ],
      ),
    );
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
    final currentUserAsync = ref.watch(currentUserProvider);

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
          postAsync.maybeWhen(
            data: (post) {
              if (post == null) return const SizedBox.shrink();
              final currentUserId = currentUserAsync.valueOrNull?.uid;
              if (currentUserId == post.authorId) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent),
                  onPressed: () => _confirmDeletePost(context, post),
                );
              }
              return IconButton(
                icon: const Icon(Icons.flag_outlined, color: Colors.redAccent),
                onPressed: () => showReportSheet(context, widget.postId),
              );
            },
            orElse: () => IconButton(
              icon: const Icon(Icons.flag_outlined, color: Colors.redAccent),
              onPressed: () => showReportSheet(context, widget.postId),
            ),
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
              ],
            ),
          ),

          // ── Comment input bar ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: NewPalette.background,
              border: Border(top: BorderSide(color: NewPalette.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reply indicator
                if (_replyingToPseudonym != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.reply_rounded,
                            size: 14, color: NewPalette.primary),
                        const SizedBox(width: 4),
                        Text('Replying to $_replyingToPseudonym',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 11,
                                color: NewPalette.primary,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        GestureDetector(
                          onTap: _clearReply,
                          child: Icon(Icons.close_rounded,
                              size: 14, color: NewPalette.textMuted),
                        ),
                      ],
                    ),
                  ),
                // GIF preview above text field
                if (_commentGifUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: _commentGifUrl!,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _commentGifUrl = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.65)),
                              child: const Icon(Icons.close_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: NewPalette.primary),
                            ),
                            child: const Text('GIF',
                                style: TextStyle(
                                    color: NewPalette.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Nunito')),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    // GIF button
                    GestureDetector(
                      onTap: _pickCommentGif,
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _commentGifUrl != null
                              ? NewPalette.primarySoft
                              : NewPalette.cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _commentGifUrl != null
                                  ? NewPalette.primary.withOpacity(0.4)
                                  : NewPalette.border),
                        ),
                        child: Center(
                          child: Text('GIF',
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: _commentGifUrl != null
                                      ? NewPalette.primary
                                      : NewPalette.textMuted)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        style: const TextStyle(
                            fontSize: 14, color: NewPalette.white),
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
                        onChanged: (_) => setState(() {}),
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
                                    strokeWidth: 2,
                                    color: NewPalette.background))
                            : const Icon(Icons.send_rounded,
                                color: NewPalette.background, size: 16),
                      ),
                    ),
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

// ---------------------------------------------------------------------------
// _PostDetailBody  ← FIX: now renders post image / GIF
// ---------------------------------------------------------------------------
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
                // Community + timestamp badge
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
                // Author row
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
                // Post content text
                Text(post.content,
                    style: const TextStyle(
                        fontSize: 15, color: NewPalette.white, height: 1.6)),

                // ── FIX: Post image or GIF ─────────────────────────────────
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 14),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: post.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(height: 220, color: NewPalette.cardBg),
                          errorWidget: (_, __, ___) => Container(
                            height: 220,
                            color: NewPalette.cardBg,
                            child: Icon(Icons.broken_image_outlined,
                                color: NewPalette.textMuted),
                          ),
                        ),
                      ),
                      // GIF badge on top-right corner
                      if (post.isGif)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: NewPalette.primary),
                            ),
                            child: const Text('GIF',
                                style: TextStyle(
                                    color: NewPalette.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Nunito')),
                          ),
                        ),
                    ],
                  ),
                ],
                // ─────────────────────────────────────────────────────────────

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

// ---------------------------------------------------------------------------
// Comment node
// ---------------------------------------------------------------------------
class _FlatCommentItem {
  final WComment comment;
  final bool isReply;
  final int rootIndex;
  final int indentationLevel;

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
              WAvatar(
                pseudonym: comment.authorPseudonym,
                colorIndex: comment.authorColorIndex,
                size: avatarSize,
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
                    // Comment text
                    if (comment.content.isNotEmpty)
                      Text(
                        comment.content,
                        style: TextStyle(
                          fontSize: isNestedReply ? 12.5 : 13.5,
                          color: NewPalette.white.withOpacity(0.95),
                          height: 1.4,
                        ),
                      ),
                    // ── Comment GIF ────────────────────────────────────────
                    if (comment.gifUrl != null) ...[
                      const SizedBox(height: 6),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: comment.gifUrl!,
                              width: isNestedReply ? 160 : 200,
                              height: isNestedReply ? 100 : 130,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                  width: 200,
                                  height: 130,
                                  color: NewPalette.cardBg),
                              errorWidget: (_, __, ___) => Container(
                                  width: 200,
                                  height: 130,
                                  color: NewPalette.cardBg),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: NewPalette.primary),
                              ),
                              child: const Text('GIF',
                                  style: TextStyle(
                                      color: NewPalette.primary,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Nunito')),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // ──────────────────────────────────────────────────────
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
