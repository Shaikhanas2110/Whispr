import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NotifType { newComment, newReply, reaction, system }

class WNotification {
  final String id;
  final String userId;
  final NotifType type;
  final String title;
  final String body;
  final String? postId;
  final bool isRead;
  final DateTime createdAt;

  const WNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.postId,
    this.isRead = false,
    required this.createdAt,
  });

  factory WNotification.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WNotification(
      id: doc.id,
      userId: d['userId'] ?? '',
      type: NotifType.values.firstWhere(
        (e) => e.name == (d['type'] ?? 'system'),
        orElse: () => NotifType.system,
      ),
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      postId: d['postId'],
      isRead: d['isRead'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get emoji {
    switch (type) {
      case NotifType.newComment: return '💬';
      case NotifType.newReply:   return '↩️';
      case NotifType.reaction:   return '🔥';
      case NotifType.system:     return '📢';
    }
  }
}

// ── Provider ──────────────────────────────────────────────
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

final notificationsProvider = StreamProvider<List<WNotification>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return NotificationService().streamForUser(uid);
});

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).when(
    data: (list) => list.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

class NotificationService {
  final _db = FirebaseFirestore.instance;
  static const _col = 'notifications';

  Stream<List<WNotification>> streamForUser(String uid) {
    return _db
        .collection(_col)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => WNotification.fromFirestore(d)).toList());
  }

  Future<void> markRead(String id) =>
      _db.collection(_col).doc(id).update({'isRead': true});

  Future<void> markAllRead(String uid) async {
    final batch = _db.batch();
    final unread = await _db
        .collection(_col)
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    for (final d in unread.docs) {
      batch.update(d.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteAll(String uid) async {
    final batch = _db.batch();
    final all = await _db.collection(_col).where('userId', isEqualTo: uid).get();
    for (final d in all.docs) batch.delete(d.reference);
    await batch.commit();
  }
}
