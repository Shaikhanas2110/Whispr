import 'package:flutter_test/flutter_test.dart';
import 'package:whispr/app/constants.dart';

void main() {
  group('Pseudonym Generation', () {
    test('adjectives list is non-empty', () {
      expect(AppConstants.adjectives, isNotEmpty);
    });

    test('nouns list is non-empty', () {
      expect(AppConstants.nouns, isNotEmpty);
    });

    test('default communities have required fields', () {
      for (final c in AppConstants.defaultCommunities) {
        expect(c.containsKey('id'), isTrue);
        expect(c.containsKey('name'), isTrue);
        expect(c.containsKey('icon'), isTrue);
        expect(c.containsKey('color'), isTrue);
        expect(c.containsKey('members'), isTrue);
      }
    });

    test('reaction map has expected keys', () {
      expect(AppConstants.reactions.keys, containsAll(['fire', 'heart', 'laugh', 'sad', 'shock', 'down']));
    });

    test('max post length is 500 for free users', () {
      expect(AppConstants.maxPostLength, 500);
    });

    test('max post length is 1000 for premium users', () {
      expect(AppConstants.maxPostLengthPremium, 1000);
    });
  });

  group('Post Limits', () {
    test('posts per page is 20', () {
      expect(AppConstants.postsPerPage, 20);
    });

    test('max strikes before ban is 3', () {
      expect(AppConstants.maxStrikes, 3);
    });
  });
}
