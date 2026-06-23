import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:whispr/app/constants.dart';
import '../domain/post_model.dart';
import '../data/post_service.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../../../shared/widgets/w_avatar.dart';
import '../../../shared/widgets/hashtag_text.dart';

class NewPalette {
  static const Color primary = Color(0xFFA7ED10); // Vibrant Lime
  static const Color surfaceMuted = Color(0xFFB5B5B5); // Neutral Gray
  static const Color background = Color(0xFF000000); // Deep Black
  static const Color white = Color(0xFFFFFFFF); // Crisp White

  // Frosted translucent shades for true glass layering
  static final Color glassBg = white.withOpacity(0.03);
  static final Color glassBorder = white.withOpacity(0.08);
  static final Color primarySoft = primary.withOpacity(0.12);
  static final Color textMuted = white.withOpacity(0.45);
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
  bool _reacting = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void didUpdateWidget(PostCard old) {
    super.didUpdateWidget(old);
    // FIX: Only sync parent updates if the user isn't interacting with reactions.
    // If we have an active reaction locally, preserve our count and state over the stream snapshot.
    if (!_reacting) {
      _post = widget.post;
    } else {
      // Keep the incoming image/content changes, but protect the live counting state variables
      _post = widget.post.copyWith(
        myReaction: _post.myReaction,
        reactions: _post.reactions,
      );
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
              emoji: '📤',
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
              emoji: '📋',
              label: 'Copy text',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _MenuTile(
              emoji: '🚩',
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

  Future<void> _react(String type) async {
    if (_reacting) return;

    final String currentReaction = _post.myReaction ?? '';
    final bool isRemovingSameReaction = currentReaction == type;

    setState(() {
      _reacting = true;

      final reactions = Map<String, int>.from(_post.reactions);

      // Remove old reaction if there is one
      if (currentReaction.isNotEmpty) {
        reactions[currentReaction] =
            max(0, (reactions[currentReaction] ?? 1) - 1);
      }

      if (isRemovingSameReaction) {
        // User tapped the same reaction again -> remove it
        _post = _post.copyWith(
          myReaction: '',
          reactions: reactions,
        );
      } else {
        // Add the new reaction
        reactions[type] = (reactions[type] ?? 0) + 1;

        _post = _post.copyWith(
          myReaction: type,
          reactions: reactions,
        );
      }
    });

    try {
      await ref.read(postServiceProvider).reactToPost(widget.post.id, type);
    } catch (e) {
      if (mounted) {
        setState(() {
          _post = widget.post; // rollback on failure
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _reacting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasReacted = _post.myReaction != null && _post.myReaction!.isNotEmpty;

    final commData = AppConstants.defaultCommunities.firstWhere(
      (c) => c['name'] == _post.communityName,
      orElse: () => {'color': 0xFFBF6B3D},
    );
    final commColor = Color(commData['color'] as int);

    return GestureDetector(
        onTap: widget.onTap ?? () => context.push('/post/${_post.id}'),
        onLongPress: () => _showContextMenu(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: hasReacted
                    ? NewPalette.primary.withOpacity(0.04)
                    : NewPalette.glassBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: hasReacted
                      ? NewPalette.primary.withOpacity(0.35)
                      : NewPalette.glassBorder,
                  width: hasReacted ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(post: _post, commColor: commColor),
                  if (_post.imageUrl != null)
                    _ImageSection(url: _post.imageUrl!),
                  _Content(post: _post),
                  _ReactionsBar(post: _post, onReact: _react),
                ],
              ),
            ),
          ),
        ));
  }
}

class _Header extends StatelessWidget {
  final WPost post;
  final Color commColor;
  const _Header({required this.post, required this.commColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          WAvatar(
            pseudonym: post.authorPseudonym,
            colorIndex: post.authorColorIndex,
            isPremium: post.authorIsPremium,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post.authorPseudonym,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: NewPalette.white,
                      ),
                    ),
                    if (post.authorIsPremium) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: NewPalette.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '✦ PRO',
                          style: TextStyle(
                            fontSize: 8,
                            color: NewPalette.background,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  timeago.format(post.createdAt),
                  style: TextStyle(fontSize: 11, color: NewPalette.textMuted),
                ),
              ],
            ),
          ),
          // Glassmorphic Capsule for Community Target
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: commColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: commColor.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _communityIcon(post.communityName),
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(width: 5),
                Text(
                  post.communityName,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    color: commColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _communityIcon(String name) {
    final community = AppConstants.defaultCommunities.firstWhere(
      (c) => c['name'] == name,
      orElse: () => {'icon': '💬'},
    );
    return community['icon'] as String;
  }
}

class _Content extends StatelessWidget {
  final WPost post;
  const _Content({required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: HashtagText(
        text: post.content,
        maxLines: 6,
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  final String url;
  const _ImageSection({required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: url,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              Container(height: 180, color: NewPalette.glassBg),
          errorWidget: (_, __, ___) => Container(
            height: 180,
            color: NewPalette.glassBg,
            child:
                Icon(Icons.broken_image_outlined, color: NewPalette.textMuted),
          ),
        ),
      ),
    );
  }
}

class _ReactionsBar extends StatelessWidget {
  final WPost post;
  final Future<void> Function(String) onReact;
  const _ReactionsBar({required this.post, required this.onReact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppConstants.reactions.entries.map((e) {
                  final isActive = post.myReaction == e.key;
                  final count = post.reactions[e.key] ?? 0;
                  return GestureDetector(
                    onTap: () => onReact(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? NewPalette.primarySoft
                            : NewPalette.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? NewPalette.primary
                              : NewPalette.glassBorder,
                          width: isActive ? 1.2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(e.value, style: const TextStyle(fontSize: 13)),
                          if (count > 0) ...[
                            const SizedBox(width: 5),
                            Text(
                              count > 999
                                  ? '${(count / 1000).toStringAsFixed(1)}k'
                                  : '$count',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 11,
                                color: isActive
                                    ? NewPalette.primary
                                    : NewPalette.surfaceMuted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Frosted Glass Comment Button
          GestureDetector(
            onTap: () => context.push('/post/${post.id}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: NewPalette.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NewPalette.glassBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 13, color: NewPalette.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    '${post.commentCount}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: NewPalette.textMuted,
                      fontWeight: FontWeight.w800,
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
          color: col,
        ),
      ),
      onTap: onTap,
    );
  }
}
