import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Inline, tap-to-play video player used for post media (feed card + detail
/// screen).
///
/// Performance notes:
/// - The underlying [VideoPlayerController] is only created once the widget
///   actually scrolls into view (via [VisibilityDetector]), not the instant
///   the feed builds the card. This stops a long feed from opening dozens of
///   simultaneous network video buffers at once, which is what was causing
///   the jank/lag.
/// - When the widget scrolls mostly out of view it's paused (not disposed),
///   so scrolling back to it doesn't have to re-buffer from scratch.
/// - The controller is fully disposed when the widget itself is removed
///   from the tree (e.g. the card is unmounted).
class PostVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double height;
  final BorderRadius borderRadius;

  const PostVideoPlayer({
    super.key,
    required this.videoUrl,
    this.height = 220,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _initializing = false;
  bool _initialized = false;
  bool _isMuted = true;
  bool _isPlaying = false;
  bool _failed = false;
  bool _everVisible = false;

  // Keep state alive briefly so fast scroll-past-and-back doesn't thrash,
  // but we still gate actual network/controller work on visibility.
  @override
  bool get wantKeepAlive => true;

  Future<void> _ensureInitialized() async {
    if (_initialized || _initializing || _failed) return;
    _initializing = true;
    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(0); // start muted, like most social feeds
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initialized = true;
        _initializing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _failed = true;
          _initializing = false;
        });
      }
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final visibleFraction = info.visibleFraction;
    if (visibleFraction > 0.4) {
      _everVisible = true;
      // Scrolled into view — load it if we haven't yet.
      _ensureInitialized();
    } else {
      // Scrolled mostly out of view — pause playback to free up CPU/network,
      // but keep the buffered controller around for a quick resume.
      final c = _controller;
      if (c != null && c.value.isPlaying) {
        c.pause();
        if (mounted) setState(() => _isPlaying = false);
      }
    }
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      if (_isPlaying) {
        c.pause();
        _isPlaying = false;
      } else {
        c.play();
        _isPlaying = true;
      }
    });
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      _isMuted = !_isMuted;
      c.setVolume(_isMuted ? 0 : 1);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin

    return VisibilityDetector(
      key: ValueKey('post-video-${widget.videoUrl}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_failed) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: widget.borderRadius,
        ),
        child: Center(
          child: Icon(Icons.error_outline_rounded,
              color: Colors.white.withOpacity(0.45)),
        ),
      );
    }

    if (!_initialized || _controller == null) {
      // Lightweight placeholder — no network/decoder work happens until
      // this card is actually visible.
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: widget.borderRadius,
        ),
        child: Center(
          child: _everVisible
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.play_circle_outline_rounded,
                  color: Colors.white.withOpacity(0.45), size: 36),
        ),
      );
    }

    final controller = _controller!;
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: GestureDetector(
        onTap: _togglePlay,
        child: Container(
          height: widget.height,
          width: double.infinity,
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
              if (!_isPlaying)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 32),
                ),
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.55),
                    ),
                    child: Icon(
                      _isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
