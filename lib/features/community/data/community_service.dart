import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/constants.dart';

final communityServiceProvider =
    Provider<CommunityService>((ref) => CommunityService());

/// Tracks which communities the current user has joined.
final joinedCommunitiesProvider = StreamProvider<List<String>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .snapshots()
      .map((d) => List<String>.from(d.data()?['joinedCommunities'] ?? []));
});

/// Globally watches your network database stream container for instant multi-screen sync
final communitiesStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(communityServiceProvider).streamAllCommunities();
});

class CommunityService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Append these two methods inside your existing CommunityService class in community_service.dart

  /// Streams all standard fallback communities combined with custom ones created in Firestore
  Stream<List<Map<String, dynamic>>> streamAllCommunities() {
    return _db
        .collection(AppConstants.communitiesCollection)
        .snapshots()
        .map((snapshot) {
      // Start with your static default list as the baseline anchor
      final List<Map<String, dynamic>> combinedList =
          List<Map<String, dynamic>>.from(AppConstants.defaultCommunities);

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Prevent duplicating item records if they share matching IDs
        combinedList.removeWhere((element) => element['id'] == doc.id);

        combinedList.add({
          'id': doc.id,
          'name': data['name'] ?? doc.id,
          'icon': data['icon'] ?? '💬',
          'color': data['color'] ?? 0xFFB5B5B5,
          'members': data['memberCount'] ?? 0,
        });
      }
      return combinedList;
    });
  }

  /// Stores a brand-new user created tribe directly into Firestore collection buckets
  Future<void> saveCustomCommunity(Map<String, dynamic> communityData) async {
    final String docId = communityData['id'] as String;
    await _db.collection(AppConstants.communitiesCollection).doc(docId).set({
      'name': communityData['name'],
      'icon': communityData['icon'],
      'color': communityData['color'],
      'memberCount': communityData['members'],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> joinCommunity(String communityId) async {
    if (_uid == null) return;

    final userRef = _db.collection(AppConstants.usersCollection).doc(_uid);
    final communityRef =
        _db.collection(AppConstants.communitiesCollection).doc(communityId);

    final batch = _db.batch();

    // ✅ FIX: use set with merge instead of update
    batch.set(
      userRef,
      {
        'joinedCommunities': FieldValue.arrayUnion([communityId])
      },
      SetOptions(merge: true),
    );

    batch.set(
      communityRef,
      {'memberCount': FieldValue.increment(1)},
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> leaveCommunity(String communityId) async {
    if (_uid == null) return;

    final userRef = _db.collection(AppConstants.usersCollection).doc(_uid);
    final communityRef =
        _db.collection(AppConstants.communitiesCollection).doc(communityId);

    final batch = _db.batch();

    batch.set(
      userRef,
      {
        'joinedCommunities': FieldValue.arrayRemove([communityId])
      },
      SetOptions(merge: true),
    );

    batch.set(
      communityRef,
      {'memberCount': FieldValue.increment(-1)},
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<bool> isJoined(String communityId) async {
    if (_uid == null) return false;

    final doc =
        await _db.collection(AppConstants.usersCollection).doc(_uid).get();

    final list = List<String>.from(doc.data()?['joinedCommunities'] ?? []);

    return list.contains(communityId);
  }
}
