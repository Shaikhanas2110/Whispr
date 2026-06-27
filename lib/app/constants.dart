class AppConstants {
  // Firestore collections
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String communitiesCollection = 'communities';
  static const String reportsCollection = 'reports';
  static const String reactionsCollection = 'reactions';

  static const giphyApiKey = 'xgoOqu43FnGUA7Rn9PMZOFZTjLU3XUPS';

  // Post limits
  static const int maxPostLength = 500;
  static const int maxPostLengthPremium = 1000;
  static const int maxCommentLength = 300;
  static const int postsPerPage = 20;
  static const int commentsPerPage = 30;

  // Moderation
  static const int maxStrikes = 3;
  static const int muteDurationMinutes = 60;

  // Pseudonym adjectives + nouns for generation
  static const List<String> adjectives = [
    'Crimson',
    'Violet',
    'Silver',
    'Golden',
    'Phantom',
    'Shadow',
    'Neon',
    'Cosmic',
    'Arctic',
    'Midnight',
    'Stellar',
    'Ancient',
    'Silent',
    'Wild',
    'Mystic',
    'Jade',
    'Azure',
    'Ember',
    'Storm',
    'Crystal',
    'Lunar',
    'Solar',
    'Prism',
    'Echo',
    'Velvet',
    'Onyx',
    'Ruby',
    'Sapphire',
    'Amber',
    'Indigo',
  ];

  static const List<String> nouns = [
    'Phoenix',
    'Nova',
    'Echo',
    'Tide',
    'Drift',
    'Pulse',
    'Veil',
    'Spark',
    'Bloom',
    'Crest',
    'Dusk',
    'Dawn',
    'Flux',
    'Glow',
    'Haze',
    'Mist',
    'Reef',
    'Shard',
    'Vale',
    'Wind',
    'Rune',
    'Sage',
    'Wren',
    'Lark',
    'Hawk',
    'Wolf',
    'Bear',
    'Fox',
    'Lynx',
    'Rook',
  ];

  // Reaction types
  static const Map<String, String> reactions = {
    'fire': '🔥',
    'heart': '❤️',
    'laugh': '😂',
    'sad': '😢',
    'shock': '😱',
    'down': '👎',
  };

  // Communities (seed data)
  static const List<Map<String, dynamic>> defaultCommunities = [
    {
      'id': 'confessions',
      'name': 'Confessions',
      'icon': '🙈',
      'color': 0xFFF87171,
      'members': 24500
    },
    {
      'id': 'mental_health',
      'name': 'Mental Health',
      'icon': '💚',
      'color': 0xFF4ADE80,
      'members': 18200
    },
    {
      'id': 'genz_talk',
      'name': 'Gen Z Talk',
      'icon': '⚡',
      'color': 0xFF7C6EFF,
      'members': 31000
    },
    {
      'id': 'relationships',
      'name': 'Relationships',
      'icon': '💔',
      'color': 0xFFF472B6,
      'members': 15600
    },
    {
      'id': 'rants',
      'name': 'Rants',
      'icon': '🔥',
      'color': 0xFFFCD34D,
      'members': 22100
    },
    {
      'id': 'career',
      'name': 'Career & Work',
      'icon': '💼',
      'color': 0xFF60A5FA,
      'members': 9800
    },
    {
      'id': 'philosophy',
      'name': 'Philosophy',
      'icon': '🌀',
      'color': 0xFFA78BFA,
      'members': 7400
    },
    {
      'id': 'humor',
      'name': 'Dark Humor',
      'icon': '😈',
      'color': 0xFFFF6B6B,
      'members': 28900
    },
  ];
}
