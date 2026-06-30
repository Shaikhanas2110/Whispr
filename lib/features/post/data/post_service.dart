import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_compress/video_compress.dart';
import '../domain/post_model.dart';
import '../../auth/domain/user_model.dart';
import '../../../app/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

final postServiceProvider = Provider<PostService>((ref) => PostService());

/// Result of a paginated video-posts query — bundles the posts with the
/// Firestore cursor doc needed to fetch the next page.
class VideoPostsPage {
  final List<WPost> posts;
  final DocumentSnapshot? lastDoc;
  const VideoPostsPage({required this.posts, this.lastDoc});
}

class PostService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Fetch feeds ──────────────────────────────────────────────────────────
  // Note: all three exclude video posts (hasVideo == false) — videos only
  // ever surface in the Reels tab via fetchVideoPosts() below.
  Future<List<WPost>> fetchTrendingPosts({DocumentSnapshot? lastDoc}) async {
    var q = _db
        .collection(AppConstants.postsCollection)
        .where('status', isEqualTo: 'active')
        .where('hasVideo', isEqualTo: false)
        .orderBy('trendScore', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.postsPerPage);
    if (lastDoc != null) q = q.startAfterDocument(lastDoc);
    final snap = await q.get();
    return _enrichPosts(snap.docs);
  }

  Stream<List<WPost>> streamVideoPosts(
      {int limit = AppConstants.postsPerPage}) {
    return _db
        .collection(AppConstants.postsCollection)
        .where('status', isEqualTo: 'active')
        .where('hasVideo', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snap) => _enrichPosts(snap.docs));
  }

  Future<List<WPost>> fetchNewPosts({DocumentSnapshot? lastDoc}) async {
    var q = _db
        .collection(AppConstants.postsCollection)
        .where('status', isEqualTo: 'active')
        .where('hasVideo', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.postsPerPage);
    if (lastDoc != null) q = q.startAfterDocument(lastDoc);
    final snap = await q.get();
    return _enrichPosts(snap.docs);
  }

  Future<List<WPost>> fetchCommunityPosts(String communityId,
      {DocumentSnapshot? lastDoc}) async {
    var q = _db
        .collection(AppConstants.postsCollection)
        .where('status', isEqualTo: 'active')
        .where('communityId', isEqualTo: communityId)
        .where('hasVideo', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.postsPerPage);
    if (lastDoc != null) q = q.startAfterDocument(lastDoc);
    final snap = await q.get();
    return _enrichPosts(snap.docs);
  }

  // ── Reels feed (video-only posts) ──────────────────────────────────────
  Future<VideoPostsPage> fetchVideoPosts({DocumentSnapshot? lastDoc}) async {
    var q = _db
        .collection(AppConstants.postsCollection)
        .where('status', isEqualTo: 'active')
        .where('hasVideo', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.postsPerPage);
    if (lastDoc != null) q = q.startAfterDocument(lastDoc);
    final snap = await q.get();
    final posts = await _enrichPosts(snap.docs);
    return VideoPostsPage(
      posts: posts,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  Future<List<WPost>> _enrichPosts(List<DocumentSnapshot> docs) async {
    if (_uid == null || docs.isEmpty) {
      return docs.map((d) => WPost.fromFirestore(d)).toList();
    }

    final postIds = docs.map((d) => d.id).toList();
    final reactionDocs = await _db
        .collection(AppConstants.reactionsCollection)
        .where('userId', isEqualTo: _uid)
        .where('postId', whereIn: postIds)
        .get();

    final myReactions = <String, String>{
      for (final r in reactionDocs.docs)
        (r.data()['postId'] as String): (r.data()['reactionType'] as String)
    };

    return docs
        .map((d) => WPost.fromFirestore(d, myReaction: myReactions[d.id]))
        .toList();
  }

  // ── Cloudinary upload (images only — GIFs are stored as URLs) ────────────
  Future<String?> _uploadImage({
    File? file,
    Uint8List? webImage,
    required String uid,
  }) async {
    try {
      final uri =
          Uri.parse("https://api.cloudinary.com/v1_1/dcfsy3pdj/image/upload");

      var request = http.MultipartRequest("POST", uri);
      request.fields['upload_preset'] = 'anas2110';

      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      } else if (webImage != null) {
        request.files.add(http.MultipartFile.fromBytes('file', webImage,
            filename: 'upload.jpg'));
      } else {
        return null;
      }

      var response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        return data['secure_url'] as String?;
      }
      return null;
    } catch (e) {
      print("CLOUDINARY ERROR: $e");
      return null;
    }
  }

  // ── Cloudinary video upload ───────────────────────────────────────────────
  Future<String?> _uploadVideo({
    File? file,
    Uint8List? webVideo,
    required String uid,
    void Function(double progress)? onProgress,
  }) async {
    File? uploadFile = file;
    try {
      // Compress local video files before upload (mobile/desktop only —
      // video_compress has no web implementation, so web bytes go through
      // as-is). This is what cuts the long "uploading…" wait down.
      if (uploadFile != null && !kIsWeb) {
        try {
          final subscription = VideoCompress.compressProgress$.subscribe((p) {
            onProgress?.call((p / 100).clamp(0.0, 1.0));
          });
          final info = await VideoCompress.compressVideo(
            uploadFile.path,
            quality: VideoQuality.LowQuality,
            frameRate: 24,
            deleteOrigin: false,
            includeAudio: true,
          );
          subscription.unsubscribe();
          if (info != null && info.file != null) {
            uploadFile = info.file;
          }
        } catch (e) {
          // If compression fails for any reason, fall back to the original
          // file rather than blocking the whole post.
          print("VIDEO COMPRESS ERROR: $e");
        }
      }

      final uri =
          Uri.parse("https://api.cloudinary.com/v1_1/dcfsy3pdj/video/upload");

      var request = http.MultipartRequest("POST", uri);
      request.fields['upload_preset'] = 'anas2110';

      if (uploadFile != null) {
        request.files
            .add(await http.MultipartFile.fromPath('file', uploadFile.path));
      } else if (webVideo != null) {
        request.files.add(http.MultipartFile.fromBytes('file', webVideo,
            filename: 'upload.mp4'));
      } else {
        return null;
      }

      var response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        return data['secure_url'] as String?;
      }
      return null;
    } catch (e) {
      print("CLOUDINARY VIDEO ERROR: $e");
      return null;
    } finally {
      if (!kIsWeb) {
        // Clean up the compressed temp file once it's been uploaded.
        await VideoCompress.deleteAllCache();
      }
    }
  }

  // ── Create post ───────────────────────────────────────────────────────────
  Future<void> createPost({
    required WUser author,
    required String content,
    required String communityId,
    required String communityName,
    File? imageFile,
    Uint8List? webImage,
    String? gifUrl, // <-- NEW: direct GIF URL from Tenor
    File? videoFile, // <-- NEW: local video picked from gallery/camera
    Uint8List? webVideo, // <-- NEW: video bytes on web
    void Function(double progress)? onVideoProgress, // <-- NEW: 0.0–1.0
  }) async {
    String? imageUrl;
    String? videoUrl;

    try {
      // Video takes priority over image/GIF — a post carries one media type.
      if (videoFile != null || webVideo != null) {
        videoUrl = await _uploadVideo(
          file: videoFile,
          webVideo: webVideo,
          uid: author.uid,
          onProgress: onVideoProgress,
        );
        if (videoUrl == null) throw Exception("Video upload failed");
      }
      // If a local image was picked, upload it to Cloudinary
      else if (imageFile != null || webImage != null) {
        imageUrl = await _uploadImage(
          file: imageFile,
          webImage: webImage,
          uid: author.uid,
        );
        if (imageUrl == null) throw Exception("Image upload failed");
      }
      // If a GIF URL was provided, use it directly (no upload needed)
      else if (gifUrl != null) {
        imageUrl = gifUrl;
      }

      final docRef = _db.collection(AppConstants.postsCollection).doc();

      final post = WPost(
        id: docRef.id,
        authorId: author.uid,
        authorPseudonym: author.pseudonym,
        authorColorIndex: author.avatarColorIndex,
        authorIsPremium: author.isPremium,
        content: content,
        imageUrl: imageUrl,
        isGif: gifUrl != null, // <-- tag as GIF so UI can render correctly
        videoUrl: videoUrl,
        communityId: communityId,
        communityName: communityName,
        createdAt: DateTime.now(),
      );

      final batch = _db.batch();
      batch.set(docRef, post.toFirestore());
      batch.set(
        _db.collection(AppConstants.usersCollection).doc(author.uid),
        {'postCount': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
      await batch.commit();
    } catch (e) {
      print("CREATE POST ERROR: $e");
      rethrow;
    }
  }

  // ── React to post ─────────────────────────────────────────────────────────
  Future<void> reactToPost(String postId, String reactionType) async {
    if (_uid == null) return;

    final reactionRef = _db
        .collection(AppConstants.reactionsCollection)
        .where('userId', isEqualTo: _uid)
        .where('postId', isEqualTo: postId);
    final existing = await reactionRef.get();

    final postRef = _db.collection(AppConstants.postsCollection).doc(postId);
    final batch = _db.batch();

    if (existing.docs.isNotEmpty) {
      final oldType = existing.docs.first.data()['reactionType'] as String;
      if (oldType == reactionType) {
        batch.delete(existing.docs.first.reference);
        batch.update(postRef, {'reactions.$oldType': FieldValue.increment(-1)});
      } else {
        batch.update(
            existing.docs.first.reference, {'reactionType': reactionType});
        batch.update(postRef, {
          'reactions.$oldType': FieldValue.increment(-1),
          'reactions.$reactionType': FieldValue.increment(1),
        });
      }
    } else {
      batch.set(_db.collection(AppConstants.reactionsCollection).doc(), {
        'userId': _uid,
        'postId': postId,
        'reactionType': reactionType,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(
          postRef, {'reactions.$reactionType': FieldValue.increment(1)});
    }

    await batch.commit();
  }

  // ── Delete post ───────────────────────────────────────────────────────────
  Future<void> deletePost(String postId, String authorId) async {
    if (_uid != authorId) throw Exception('Not authorized');
    await _db
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .update({'status': 'removed'});
  }

  // ── Report post ───────────────────────────────────────────────────────────
  Future<void> reportPost(String postId, String reason) async {
    if (_uid == null) return;
    await _db.collection(AppConstants.reportsCollection).add({
      'postId': postId,
      'reporterId': _uid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Fetch single post ─────────────────────────────────────────────────────
  Future<WPost?> fetchPost(String postId) async {
    final doc =
        await _db.collection(AppConstants.postsCollection).doc(postId).get();
    if (!doc.exists) return null;
    return WPost.fromFirestore(doc);
  }

  // ── Comments stream ───────────────────────────────────────────────────────
  Stream<List<WComment>> commentsStream(String postId) {
    return _db
        .collection(AppConstants.commentsCollection)
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((s) {
      final comments = s.docs.map((d) => WComment.fromFirestore(d)).toList();
      comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return comments;
    });
  }

  // ── Add comment (now supports gifUrl) ────────────────────────────────────
  Future<void> addComment({
    required WUser author,
    required String postId,
    required String content,
    String? parentId,
    String? gifUrl, // <-- NEW: optional GIF in comments
  }) async {
    final batch = _db.batch();
    final commentRef = _db.collection(AppConstants.commentsCollection).doc();
    batch.set(commentRef, {
      'postId': postId,
      'authorId': author.uid,
      'authorPseudonym': author.pseudonym,
      'authorColorIndex': author.avatarColorIndex,
      'content': content,
      'parentId': parentId,
      'gifUrl': gifUrl, // stored as-is; null if no GIF
      'isGif': gifUrl != null,
      'likeCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection(AppConstants.postsCollection).doc(postId), {
      'commentCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  // ── Like / unlike comment ─────────────────────────────────────────────────
  Future<void> likeComment(String commentId) async {
    if (_uid == null) return;
    final likeRef = _db
        .collection(AppConstants.commentsCollection)
        .doc(commentId)
        .collection('likes')
        .doc(_uid);
    final existing = await likeRef.get();
    final commentRef =
        _db.collection(AppConstants.commentsCollection).doc(commentId);
    if (existing.exists) {
      await Future.wait([
        likeRef.delete(),
        commentRef.update({'likeCount': FieldValue.increment(-1)}),
      ]);
    } else {
      await Future.wait([
        likeRef.set({'createdAt': FieldValue.serverTimestamp()}),
        commentRef.update({'likeCount': FieldValue.increment(1)}),
      ]);
    }
  }

  // ── Like / unlike post ────────────────────────────────────────────────────
  Future<void> likePost(String postId) async {
    if (_uid == null) return;

    final likeRef = _db
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .collection('likes')
        .doc(_uid);

    final postRef = _db.collection(AppConstants.postsCollection).doc(postId);
    final existing = await likeRef.get();
    final batch = _db.batch();

    if (existing.exists) {
      batch.delete(likeRef);
      batch.update(postRef, {'likeCount': FieldValue.increment(-1)});
    } else {
      batch.set(likeRef, {
        'likedBy': _uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(postRef, {'likeCount': FieldValue.increment(1)});
    }

    await batch.commit();
  }
}
