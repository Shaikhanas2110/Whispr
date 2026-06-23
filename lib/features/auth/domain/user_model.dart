import 'package:cloud_firestore/cloud_firestore.dart';

class WUser {
  final String uid;
  final String pseudonym;
  final int avatarColorIndex;
  final bool isPremium;
  final int strikeCount;
  final bool isBanned;
  final bool isMuted;
  final DateTime? muteEndsAt;
  final DateTime joinedAt;
  final List<String> joinedCommunities;
  final int postCount;
  final int reactionCount;

  const WUser({
    required this.uid,
    required this.pseudonym,
    required this.avatarColorIndex,
    this.isPremium = false,
    this.strikeCount = 0,
    this.isBanned = false,
    this.isMuted = false,
    this.muteEndsAt,
    required this.joinedAt,
    this.joinedCommunities = const [],
    this.postCount = 0,
    this.reactionCount = 0,
  });

  factory WUser.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WUser(
      uid: doc.id,
      pseudonym: d['pseudonym'] ?? 'Anonymous',
      avatarColorIndex: d['avatarColorIndex'] ?? 0,
      isPremium: d['isPremium'] ?? false,
      strikeCount: d['strikeCount'] ?? 0,
      isBanned: d['isBanned'] ?? false,
      isMuted: d['isMuted'] ?? false,
      muteEndsAt: (d['muteEndsAt'] as Timestamp?)?.toDate(),
      joinedAt: (d['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      joinedCommunities: List<String>.from(d['joinedCommunities'] ?? []),
      postCount: d['postCount'] ?? 0,
      reactionCount: d['reactionCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'pseudonym': pseudonym,
    'avatarColorIndex': avatarColorIndex,
    'isPremium': isPremium,
    'strikeCount': strikeCount,
    'isBanned': isBanned,
    'isMuted': isMuted,
    'muteEndsAt': muteEndsAt != null ? Timestamp.fromDate(muteEndsAt!) : null,
    'joinedAt': Timestamp.fromDate(joinedAt),
    'joinedCommunities': joinedCommunities,
    'postCount': postCount,
    'reactionCount': reactionCount,
  };

  WUser copyWith({
    String? pseudonym,
    int? avatarColorIndex,
    bool? isPremium,
    int? strikeCount,
    bool? isBanned,
    bool? isMuted,
    DateTime? muteEndsAt,
    List<String>? joinedCommunities,
    int? postCount,
    int? reactionCount,
  }) => WUser(
    uid: uid,
    pseudonym: pseudonym ?? this.pseudonym,
    avatarColorIndex: avatarColorIndex ?? this.avatarColorIndex,
    isPremium: isPremium ?? this.isPremium,
    strikeCount: strikeCount ?? this.strikeCount,
    isBanned: isBanned ?? this.isBanned,
    isMuted: isMuted ?? this.isMuted,
    muteEndsAt: muteEndsAt ?? this.muteEndsAt,
    joinedAt: joinedAt,
    joinedCommunities: joinedCommunities ?? this.joinedCommunities,
    postCount: postCount ?? this.postCount,
    reactionCount: reactionCount ?? this.reactionCount,
  );
}
