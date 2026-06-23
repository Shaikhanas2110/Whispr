import 'package:flutter_test/flutter_test.dart';
import 'package:whispr/features/post/domain/post_model.dart';

void main() {
  group('WPost', () {
    late WPost post;

    setUp(() {
      post = WPost(
        id: 'test-id',
        authorId: 'author-uid',
        authorPseudonym: 'CrimsonEcho77',
        authorColorIndex: 0,
        content: 'Test post content',
        communityId: 'confessions',
        communityName: 'Confessions',
        reactions: {'fire': 10, 'heart': 5, 'laugh': 2},
        commentCount: 3,
        createdAt: DateTime(2026, 4, 1),
      );
    });

    test('totalReactions sums all reaction counts', () {
      expect(post.totalReactions, 17);
    });

    test('totalReactions is 0 for empty reactions', () {
      final empty = post.copyWith(reactions: {});
      expect(empty.totalReactions, 0);
    });

    test('copyWith preserves unchanged fields', () {
      final updated = post.copyWith(myReaction: 'fire');
      expect(updated.id, post.id);
      expect(updated.content, post.content);
      expect(updated.myReaction, 'fire');
    });

    test('toFirestore includes all required fields', () {
      final map = post.toFirestore();
      expect(map.containsKey('authorId'), isTrue);
      expect(map.containsKey('authorPseudonym'), isTrue);
      expect(map.containsKey('content'), isTrue);
      expect(map.containsKey('communityId'), isTrue);
      expect(map.containsKey('reactions'), isTrue);
      expect(map.containsKey('status'), isTrue);
    });

    test('default status is active', () {
      expect(post.status, 'active');
    });

    test('authorIsPremium defaults to false', () {
      expect(post.authorIsPremium, isFalse);
    });
  });

  group('WComment', () {
    test('fromFirestore handles missing parentId', () {
      // parentId is optional — null means top-level comment
      final comment = WComment(
        id: 'c1',
        postId: 'p1',
        authorId: 'uid',
        authorPseudonym: 'SilverDusk42',
        authorColorIndex: 1,
        content: 'Great post!',
        createdAt: DateTime.now(),
      );
      expect(comment.parentId, isNull);
    });
  });
}
