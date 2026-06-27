import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/post_model.dart';
import '../data/post_service.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../../../shared/widgets/w_avatar.dart';
import '../../../shared/widgets/hashtag_text.dart';

class NewPalette {
  static const Color primary = Color(0xFFA7ED10); // Vibrant Lime
  static const Color background = Color(0xFF000000); // Pure Reddit Black
  static const Color white = Color(0xFFFFFFFF);

  static final Color glassBorder = white.withOpacity(0.08);
  static final Color textMuted = white.withOpacity(0.45);
  static final Color buttonBg = white.withOpacity(0.06); // Muted capsule fill
  static final Color primarySoft =
      primary.withOpacity(0.15); // Translucent active highlight
}

class PostCard extends ConsumerStatefulWidget {
  final WPost post;
  final int index;
  final VoidCallback? onTap;

  const PostCard({super.key, required this.post, this.index = 0, this.onTap});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  late WPost _post;
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _post = widget.post;

    // Dynamically safely extract fields to stay fully compatible with backend definitions
    try {
      _likeCount = (_post as dynamic).likeCount ?? 0;
    } catch (_) {
      _likeCount = 0;
    }
  }

  @override
  void didUpdateWidget(PostCard old) {
    super.didUpdateWidget(old);
    if (widget.post != old.post) {
      setState(() {
        _post = widget.post;
        try {
          _likeCount = (_post as dynamic).likeCount ?? 0;
        } catch (_) {}
      });
    }
  }

  // Handles fast, lag-free state updates locally before committing down to database networks
  Future<void> _toggleLike() async {
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likeCount = max(0, _likeCount - 1);
      } else {
        _isLiked = true;
        _likeCount += 1;
      }
    });

    try {
      // Dispatches the state mutation straight into the database service pipeline
      await ref.read(postServiceProvider).likePost(_post.id);
    } catch (e) {
      // Fallback rollback safety handler if net configurations drop out
      setState(() {
        if (_isLiked) {
          _isLiked = false;
          _likeCount = max(0, _likeCount - 1);
        } else {
          _isLiked = true;
          _likeCount += 1;
        }
      });
    }
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NewPalette.background,
      shape: Border(top: BorderSide(color: NewPalette.glassBorder, width: 1.5)),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                  color: NewPalette.glassBorder,
                  borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 12),
            _MenuTile(
              emoji: '🔗',
              label: 'Share post',
              onTap: () async {
                Navigator.pop(context);
                final url = 'https://whispr.app/post/${_post.id}';
                final preview = _post.content.length > 100
                    ? '${_post.content.substring(0, 100)}…'
                    : _post.content;
                await Share.share('$preview\n\n$url',
                    subject: 'Check this Whispr 🫧');
              },
            ),
            _MenuTile(
              emoji: '🏳️',
              label: 'Report post',
              color: Colors.redAccent,
              onTap: () {
                Navigator.pop(context);
                showReportSheet(context, _post.id);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? () => context.push('/post/${_post.id}'),
      child: Container(
        color: NewPalette.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Identity header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  WAvatar(
                    pseudonym: _post.authorPseudonym,
                    colorIndex: _post.authorColorIndex,
                    isPremium: _post.authorIsPremium,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'r/${_post.communityName.replaceAll(' ', '')}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: NewPalette.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeago.format(_post.createdAt, locale: 'en_short'),
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: NewPalette.textMuted),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.more_horiz_rounded,
                        color: NewPalette.textMuted, size: 20),
                    onPressed: () => _showContextMenu(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content Image Frame (supports both static images and GIFs)
            if (_post.imageUrl != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: _post.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(height: 180, color: NewPalette.buttonBg),
                        errorWidget: (_, __, ___) => Container(
                          height: 180,
                          color: NewPalette.buttonBg,
                          child: Icon(Icons.broken_image_outlined,
                              color: NewPalette.textMuted),
                        ),
                      ),
                    ),
                    if (_post.isGif)
                      Positioned(
                        bottom: 8,
                        left: 8,
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
              ),

            // Main Body Content Text
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: HashtagText(
                text: _post.content,
                maxLines: 4,
              ),
            ),

            // Reddit tray bar layout
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // 1. FIXED: Clean Interactive Like Capsule Button Engine
                  GestureDetector(
                    onTap: _toggleLike,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: _isLiked
                            ? NewPalette.primarySoft
                            : NewPalette.buttonBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isLiked
                              ? NewPalette.primary.withOpacity(0.3)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: _isLiked
                                ? NewPalette.primary
                                : NewPalette.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_likeCount',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: _isLiked
                                  ? NewPalette.primary
                                  : NewPalette.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Comments Button Capsule
                  GestureDetector(
                    onTap:
                        widget.onTap ?? () => context.push('/post/${_post.id}'),
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: NewPalette.buttonBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 15, color: NewPalette.white),
                          const SizedBox(width: 6),
                          Text(
                            '${_post.commentCount}',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: NewPalette.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),

                  // 3. Right side utility triggers
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: NewPalette.buttonBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.emoji_events_outlined,
                        size: 18, color: NewPalette.white),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final url = 'https://whispr.app/post/${_post.id}';
                      await Share.share(_post.content + '\n\n' + url);
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: NewPalette.buttonBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.ios_share_rounded,
                          size: 16, color: NewPalette.white),
                    ),
                  ),
                ],
              ),
            ),

            // Clean separator line matching line splits between posts
            Container(height: 0.5, color: NewPalette.glassBorder),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MenuTile(
      {required this.emoji,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final col = color ?? NewPalette.white;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: col.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
      ),
      title: Text(
        label,
        style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: col),
      ),
      onTap: onTap,
    );
  }
}
