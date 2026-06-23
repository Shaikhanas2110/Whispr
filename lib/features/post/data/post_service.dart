import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/post_model.dart';
import '../../auth/domain/user_model.dart';
import '../../../app/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

final postServiceProvider = Provider<PostService>((ref) => PostService());

class PostService {
  final _db = FirebaseFirestore.instance;

  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // *** Fetch feeds ***
  Future<List<WPost>> fetchTrendingPosts({DocumentSnapshot? lastDoc}) async {
    var q = _db
        .collection(AppConstants.postsCollection)
        .where('status', isEqualTo: 'active')
        .orderBy('trendScore', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.postsPerPage);
    if (lastDoc != null) q = q.startAfterDocument(lastDoc);
    final snap = await q.get();
    return _enrichPosts(snap.docs);
  }

  Future<List<WPost>> fetchNewPosts({DocumentSnapshot? lastDoc}) async {
    var q = _db
        .collection(AppConstants.postsCollection)
        .where('status', isEqualTo: 'active')
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
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.postsPerPage);
    if (lastDoc != null) q = q.startAfterDocument(lastDoc);
    final snap = await q.get();
    return _enrichPosts(snap.docs);
  }

  Future<List<WPost>> _enrichPosts(List<DocumentSnapshot> docs) async {
    if (_uid == null || docs.isEmpty)
      return docs.map((d) => WPost.fromFirestore(d)).toList();

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

  Future<String?> _uploadImage({
    File? file,
    Uint8List? webImage,
    required String uid,
  }) async {
    try {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/dcfsy3pdj/image/upload",
      );

      var request = http.MultipartRequest(
        "POST",
        uri,
      );

      request.fields['upload_preset'] = 'anas2110';

      // Mobile upload
      if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
          ),
        );
      }

      // Web upload
      else if (webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            webImage,
            filename: 'upload.jpg',
          ),
        );
      } else {
        return null;
      }

      var response = await request.send();

      final responseData = await response.stream.bytesToString();

      print("CLOUDINARY STATUS: ${response.statusCode}");
      print("CLOUDINARY RESPONSE: $responseData");

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);

        return data['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      print("CLOUDINARY ERROR: $e");
      return null;
    }
  }

  Future<void> createPost({
    required WUser author,
    required String content,
    required String communityId,
    required String communityName,
    File? imageFile,
    Uint8List? webImage,
  }) async {
    String? imageUrl;

    try {
      // Upload image if exists
      if (imageFile != null || webImage != null) {
        imageUrl = await _uploadImage(
          file: imageFile,
          webImage: webImage,
          uid: author.uid,
        );

        if (imageUrl == null) {
          throw Exception("Image upload failed");
        }
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
        communityId: communityId,
        communityName: communityName,
        createdAt: DateTime.now(),
      );

      final batch = _db.batch();

      batch.set(docRef, post.toFirestore());

      batch.set(
        _db.collection(AppConstants.usersCollection).doc(author.uid),
        {
          'postCount': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      print("CREATE POST ERROR: $e");
      rethrow;
    }
  }

  // *** React to post ***
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
        // *** Remove reaction ***
        batch.delete(existing.docs.first.reference);
        batch.update(postRef, {'reactions.$oldType': FieldValue.increment(-1)});
      } else {
        // *** Change reaction ***
        batch.update(
            existing.docs.first.reference, {'reactionType': reactionType});
        batch.update(postRef, {
          'reactions.$oldType': FieldValue.increment(-1),
          'reactions.$reactionType': FieldValue.increment(1),
        });
      }
    } else {
      //  *** New reaction ***
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

  // *** Delete post ***
  Future<void> deletePost(String postId, String authorId) async {
    if (_uid != authorId) throw Exception('Not authorized');
    await _db
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .update({'status': 'removed'});
  }

  // *** Report post ***
  Future<void> reportPost(String postId, String reason) async {
    if (_uid == null) return;
    await _db.collection(AppConstants.reportsCollection).add({
      'postId': postId,
      'reporterId': _uid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // *** Fetch single post ***
  Future<WPost?> fetchPost(String postId) async {
    final doc =
        await _db.collection(AppConstants.postsCollection).doc(postId).get();
    if (!doc.exists) return null;
    return WPost.fromFirestore(doc);
  }

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

  Future<void> addComment({
    required WUser author,
    required String postId,
    required String content,
    String? parentId,
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
      'likeCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection(AppConstants.postsCollection).doc(postId), {
      'commentCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

// *** Like / unlike comment (toggle) ***
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
}
