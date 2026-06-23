import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../domain/user_model.dart';
import '../../../app/constants.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Real-time stream: re-emits whenever the Firestore user doc changes
/// (pseudonym regen, premium toggle, strike count, etc.)
final currentUserProvider = StreamProvider<WUser?>((ref) {
  final auth      = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  return auth.authStateChanges().switchMap((firebaseUser) {
    if (firebaseUser == null) {
      return Stream.value(null);
    }
    return firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid)
        .snapshots()
        .map((doc) => doc.exists ? WUser.fromFirestore(doc) : null);
  });
});

class AuthService {
  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  User? get currentFirebaseUser => _auth.currentUser;
  bool  get isSignedIn          => _auth.currentUser != null;

  Future<WUser> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    final user = cred.user!;
    final docRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid);
    final doc = await docRef.get();
    if (doc.exists) return WUser.fromFirestore(doc);

    final wUser = WUser(
      uid: user.uid,
      pseudonym: _generatePseudonym(),
      avatarColorIndex: Random().nextInt(9),
      joinedAt: DateTime.now(),
    );
    await docRef.set(wUser.toFirestore());
    return wUser;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> updatePseudonym(String uid, String newPseudonym) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({'pseudonym': newPseudonym});

  String _generatePseudonym() {
    final rng  = Random();
    final adj  = AppConstants.adjectives[rng.nextInt(AppConstants.adjectives.length)];
    final noun = AppConstants.nouns   [rng.nextInt(AppConstants.nouns.length)];
    final num  = rng.nextInt(99) + 1;
    return '$adj$noun$num';
  }
}
