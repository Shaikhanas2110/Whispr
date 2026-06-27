import 'package:cloud_firestore/cloud_firestore.dart';

class WPost {
  final String id;
  final String authorId;
  final String authorPseudonym;
  final int authorColorIndex;
  final bool authorIsPremium;
  final String content;
  final String? imageUrl;
  final bool isGif; // <-- NEW: true when imageUrl points to a Tenor GIF
  final String communityId;
  final String communityName;
  final Map<String, int> reactions;
  final int commentCount;
  final int likeCount;
  final double trendScore;
  final String status; // active | removed | under_review
  final DateTime createdAt;
  final String? myReaction;

  const WPost({
    required this.id,
    required this.authorId,
    required this.authorPseudonym,
    required this.authorColorIndex,
    this.authorIsPremium = false,
    required this.content,
    this.imageUrl,
    this.isGif = false,
    required this.communityId,
    required this.communityName,
    this.reactions = const {},
    this.commentCount = 0,
    this.likeCount = 0,
    this.trendScore = 0,
    this.status = 'active',
    required this.createdAt,
    this.myReaction,
  });

  int get totalReactions => reactions.values.fold(0, (a, b) => a + b);

  factory WPost.fromFirestore(DocumentSnapshot doc, {String? myReaction}) {
    final d = doc.data() as Map<String, dynamic>;
    return WPost(
      id: doc.id,
      authorId: d['authorId'] ?? '',
      authorPseudonym: d['authorPseudonym'] ?? 'Anonymous',
      authorColorIndex: d['authorColorIndex'] ?? 0,
      authorIsPremium: d['authorIsPremium'] ?? false,
      content: d['content'] ?? '',
      imageUrl: d['imageUrl'],
      isGif: d['isGif'] ?? false,
      communityId: d['communityId'] ?? '',
      communityName: d['communityName'] ?? '',
      reactions: Map<String, int>.from(d['reactions'] ?? {}),
      commentCount: d['commentCount'] ?? 0,
      likeCount: d['likeCount'] ?? 0,
      trendScore: (d['trendScore'] ?? 0).toDouble(),
      status: d['status'] ?? 'active',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      myReaction: myReaction,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'authorId': authorId,
        'authorPseudonym': authorPseudonym,
        'authorColorIndex': authorColorIndex,
        'authorIsPremium': authorIsPremium,
        'content': content,
        'imageUrl': imageUrl,
        'isGif': isGif,
        'communityId': communityId,
        'communityName': communityName,
        'reactions': reactions,
        'commentCount': commentCount,
        'likeCount': likeCount,
        'trendScore': trendScore,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  WPost copyWith({
    String? myReaction,
    Map<String, int>? reactions,
    int? commentCount,
    int? likeCount,
  }) =>
      WPost(
        id: id,
        authorId: authorId,
        authorPseudonym: authorPseudonym,
        authorColorIndex: authorColorIndex,
        authorIsPremium: authorIsPremium,
        content: content,
        imageUrl: imageUrl,
        isGif: isGif,
        communityId: communityId,
        communityName: communityName,
        reactions: reactions ?? this.reactions,
        commentCount: commentCount ?? this.commentCount,
        likeCount: likeCount ?? this.likeCount,
        trendScore: trendScore,
        status: status,
        createdAt: createdAt,
        myReaction: myReaction ?? this.myReaction,
      );
}

class WComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorPseudonym;
  final int authorColorIndex;
  final String content;
  final String? parentId;
  final String? gifUrl; // <-- NEW: optional GIF attached to comment
  final bool isGif;
  final int likeCount;
  final bool isLiked;
  final DateTime createdAt;

  const WComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorPseudonym,
    required this.authorColorIndex,
    required this.content,
    this.parentId,
    this.gifUrl,
    this.isGif = false,
    this.likeCount = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  factory WComment.fromFirestore(DocumentSnapshot doc, {bool isLiked = false}) {
    final d = doc.data() as Map<String, dynamic>;
    return WComment(
      id: doc.id,
      postId: d['postId'] ?? '',
      authorId: d['authorId'] ?? '',
      authorPseudonym: d['authorPseudonym'] ?? 'Anonymous',
      authorColorIndex: d['authorColorIndex'] ?? 0,
      content: d['content'] ?? '',
      parentId: d['parentId'],
      gifUrl: d['gifUrl'],
      isGif: d['isGif'] ?? false,
      likeCount: d['likeCount'] ?? 0,
      isLiked: isLiked,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
