import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../post/domain/post_model.dart';
import '../../post/data/post_service.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../../../shared/widgets/w_avatar.dart';
import '../../../shared/widgets/hashtag_text.dart';
import '../data/sparks_video_cache.dart';

class ReelPalette {
  static const Color primary = Color(0xFFA7ED10);
  static const Color background = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static final Color textMuted = white.withOpacity(0.7);
}

/// Full-bleed, single-video reel card with a like/comment/share action rail
/// and bottom caption overlay — used inside the Reels PageView.
///
/// Video lifecycle is owned by [ReelVideoCache] (passed in from the screen),
/// not by this widget — the screen preloads upcoming reels ahead of time,
/// so when this card becomes active its controller is usually already
/// initialized and playback starts instantly with no buffering spinner.
class ReelCard extends ConsumerStatefulWidget {
  final WPost post;
  final bool isActive;
  final ReelVideoCache cache;

  const ReelCard({
    super.key,
    required this.post,
    required this.isActive,
    required this.cache,
  });

  @override
  ConsumerState<ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends ConsumerState<ReelCard> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _failed = false;

  bool _isLiked = false;
  int _likeCount = 0;
  bool _isProcessingLike = false;

  bool _showHeartBurst = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount;
    _attachVideo();
  }

  Future<void> _attachVideo() async {
    // Already preloaded and ready — attach immediately, no spinner.
    final existing = widget.cache.controllerFor(widget.post.id);
    if (existing != null) {
      _bindController(existing);
      return;
    }

    // Not preloaded yet (e.g. user scrolled faster than preload could keep
    // up) — fall back to loading it now.
    try {
      final c = await widget.cache.ensure(widget.post);
      if (!mounted) return;
      if (c == null) {
        setState(() => _failed = true);
        return;
      }
      _bindController(c);
    } catch (e) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _bindController(VideoPlayerController c) {
    if (!mounted) return;
    setState(() {
      _controller = c;
      _initialized = true;
      _failed = false;
    });
    if (widget.isActive) _play();
  }

  void _play() {
    _controller?.play().catchError((e) {
      debugPrint('ReelCard ${widget.post.id}: play() failed: $e');
    });
  }

  @override
  void didUpdateWidget(covariant ReelCard old) {
    super.didUpdateWidget(old);

    // The cache may hand us a controller after this widget already built
    // (e.g. preload finished late) — pick it up if we don't have one yet.
    if (_controller == null) {
      final c = widget.cache.controllerFor(widget.post.id);
      if (c != null) _bindController(c);
    }

    if (widget.isActive && !old.isActive) {
      _play();
    } else if (!widget.isActive && old.isActive) {
      _controller?.pause();
    }
  }

  @override
  void dispose() {
    // Controller lifecycle belongs to ReelVideoCache now — the screen
    // disposes it once it scrolls out of the preload window. We only pause
    // here defensively; we never dispose it ourselves.
    if (widget.isActive) {
      _controller?.pause();
    }
    super.dispose();
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
      } else {
        _play();
      }
    });
  }

  Future<void> _toggleLike() async {
    if (_isProcessingLike) return;

    setState(() {
      _isProcessingLike = true;
      if (_isLiked) {
        _isLiked = false;
        _likeCount = max(0, _likeCount - 1);
      } else {
        _isLiked = true;
        _likeCount += 1;
      }
    });

    try {
      await ref.read(postServiceProvider).likePost(widget.post.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          // Roll back on failure
          if (_isLiked) {
            _isLiked = false;
            _likeCount = max(0, _likeCount - 1);
          } else {
            _isLiked = true;
            _likeCount += 1;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessingLike = false);
    }
  }

  void _onDoubleTapLike() {
    if (!_isLiked) _toggleLike();
    setState(() => _showHeartBurst = true);
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _showHeartBurst = false);
    });
  }

  Future<void> _share() async {
    final url = 'https://whispr.app/post/${widget.post.id}';
    final preview = widget.post.content.length > 100
        ? '${widget.post.content.substring(0, 100)}…'
        : widget.post.content;
    await Share.share('$preview\n\n$url', subject: 'Check this Whispr reel 🎬');
  }

  void _openComments() {
    context.push('/post/${widget.post.id}');
  }

  void _showContextMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ReelPalette.background,
      shape: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.5)),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.redAccent),
              title: const Text('Report reel',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                showReportSheet(context, widget.post.id);
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
    final post = widget.post;

    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: _onDoubleTapLike,
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Video layer ──────────────────────────────────────────────
            if (_failed)
              const Center(
                child: Icon(Icons.error_outline_rounded,
                    color: ReelPalette.white, size: 40),
              )
            else if (!_initialized || _controller == null)
              const Center(
                child: CircularProgressIndicator(color: ReelPalette.primary),
              )
            else
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),

            // Pause indicator
            if (_initialized &&
                _controller != null &&
                !_controller!.value.isPlaying)
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.4),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 36),
                ),
              ),

            // Double-tap heart burst
            AnimatedOpacity(
              opacity: _showHeartBurst ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: const Center(
                child: Icon(Icons.favorite_rounded,
                    color: ReelPalette.primary, size: 110),
              ),
            ),

            // ── Bottom caption overlay ───────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 60, 80, 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.78),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        WAvatar(
                          pseudonym: post.authorPseudonym,
                          colorIndex: post.authorColorIndex,
                          isPremium: post.authorIsPremium,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            post.authorPseudonym,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: ReelPalette.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'r/${post.communityName.replaceAll(' ', '')}',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: ReelPalette.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (post.content.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      DefaultTextStyle(
                        style: const TextStyle(
                            color: ReelPalette.white,
                            fontSize: 13,
                            height: 1.4),
                        child: HashtagText(text: post.content, maxLines: 2),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Right-side action rail ───────────────────────────────────
            Positioned(
              right: 10,
              bottom: 100,
              child: Column(
                children: [
                  _ReelActionButton(
                    icon: _isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isLiked ? ReelPalette.primary : ReelPalette.white,
                    label: '$_likeCount',
                    onTap: _toggleLike,
                  ),
                  const SizedBox(height: 22),
                  _ReelActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: ReelPalette.white,
                    label: '${post.commentCount}',
                    onTap: _openComments,
                  ),
                  const SizedBox(height: 22),
                  _ReelActionButton(
                    icon: Icons.ios_share_rounded,
                    color: ReelPalette.white,
                    label: 'Share',
                    onTap: _share,
                  ),
                  const SizedBox(height: 22),
                  _ReelActionButton(
                    icon: Icons.more_horiz_rounded,
                    color: ReelPalette.white,
                    label: '',
                    onTap: _showContextMenu,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ReelActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ReelPalette.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
