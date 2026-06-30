import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../../post/domain/post_model.dart';

class ReelVideoCache {
  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, Future<void>> _initializing = {};

  VideoPlayerController? controllerFor(String postId) => _controllers[postId];

  Future<VideoPlayerController?> ensure(WPost post) async {
    final id = post.id;
    final url = post.videoUrl;
    if (url == null || url.isEmpty) return null;

    final existing = _controllers[id];
    if (existing != null) return existing;

    final inFlight = _initializing[id];
    if (inFlight != null) {
      await inFlight;
      return _controllers[id];
    }

    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    final future = c.initialize().then((_) {
      c.setLooping(true);
      _controllers[id] = c;
    }).catchError((e, st) {
      debugPrint('ReelVideoCache: preload failed for $id: $e');
      c.dispose();
    });

    _initializing[id] = future;
    await future;
    _initializing.remove(id);
    return _controllers[id];
  }

  /// Fire-and-forget preload — call this for reels just ahead of the
  /// current one so they're ready by the time the user scrolls to them.
  void preload(WPost post) {
    // ignore: unawaited_futures
    ensure(post);
  }

  /// Disposes every cached controller whose post id is NOT in [keepIds].
  /// Call this on every page change so the cache doesn't grow unbounded as
  /// the user scrolls through many reels.
  void disposeExcept(Set<String> keepIds) {
    final toRemove =
        _controllers.keys.where((id) => !keepIds.contains(id)).toList();
    for (final id in toRemove) {
      _controllers.remove(id)?.dispose();
    }
    _initializing.removeWhere((id, _) => !keepIds.contains(id));
  }

  void disposeAll() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _initializing.clear();
  }
}
