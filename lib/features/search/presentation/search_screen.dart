import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../post/domain/post_model.dart';
import '../../post/presentation/post_card.dart';
import '../../../app/constants.dart';

// Locally defined palette tokens based on your specified hex codes
class NewPalette {
  static const Color primary = Color(0xFFA7ED10); // Vibrant Lime
  static const Color surfaceMuted = Color(0xFFB5B5B5); // Neutral Gray
  static const Color background = Color(0xFF000000); // Deep Black
  static const Color white = Color(0xFFFFFFFF); // Crisp White

  // Derived style opacities for sleek UI nesting
  static final Color cardBg = surfaceMuted.withOpacity(0.12);
  static final Color border = surfaceMuted.withOpacity(0.25);
  static final Color primarySoft = primary.withOpacity(0.15);
  static final Color textMuted = surfaceMuted.withOpacity(0.7);
}

// ── Search Service ────────────────────────────────────────────
class SearchService {
  final _db = FirebaseFirestore.instance;

  Future<List<WPost>> searchPosts(String query) async {
    if (query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();
    final snap = await _db
        .collection(AppConstants.postsCollection)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snap.docs
        .map((d) => WPost.fromFirestore(d))
        .where((p) =>
            p.content.toLowerCase().contains(q) ||
            p.communityName.toLowerCase().contains(q) ||
            p.authorPseudonym.toLowerCase().contains(q))
        .take(30)
        .toList();
  }

  Future<List<WPost>> searchByHashtag(String tag) async {
    final snap = await _db
        .collection(AppConstants.postsCollection)
        .where('status', isEqualTo: 'active')
        .where('hashtags', arrayContains: tag.toLowerCase())
        .orderBy('createdAt', descending: true)
        .limit(30)
        .get();
    return snap.docs.map((d) => WPost.fromFirestore(d)).toList();
  }
}

final searchServiceProvider = Provider<SearchService>((ref) => SearchService());

final _searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider.family<List<WPost>, String>((ref, query) {
  if (query.trim().isEmpty) return Future.value([]);
  return ref.read(searchServiceProvider).searchPosts(query);
});

// ── Search Screen ─────────────────────────────────────────────
class SearchScreen extends ConsumerStatefulWidget {
  final String? initialHashtag;
  const SearchScreen({super.key, this.initialHashtag});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _ctrl;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final init = widget.initialHashtag ?? '';
    _ctrl = TextEditingController(text: init);
    _query = init;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewPalette.background,
      appBar: AppBar(
        backgroundColor: NewPalette.background,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: NewPalette.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Container(
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: NewPalette.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NewPalette.border),
          ),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            style: const TextStyle(fontSize: 14, color: NewPalette.white),
            cursorColor: NewPalette.primary,
            decoration: InputDecoration(
              hintText: 'Search posts, hashtags, people…',
              hintStyle: TextStyle(color: NewPalette.textMuted, fontSize: 13),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: Icon(Icons.search_rounded,
                  color: NewPalette.textMuted, size: 20),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              suffixIcon: _query.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _ctrl.clear();
                        setState(() => _query = '');
                      },
                      child: Icon(Icons.clear_rounded,
                          size: 18, color: NewPalette.textMuted),
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _query = v),
            onSubmitted: (v) => setState(() => _query = v),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: NewPalette.border),
        ),
      ),
      body: _query.trim().isEmpty
          ? _SuggestionsPanel(
              onTap: (s) {
                final clean =
                    s.replaceAll(RegExp(r'^[^\w]+'), '').split(' ').last;
                _ctrl.text = clean;
                setState(() => _query = clean);
              },
            )
          : _ResultsPanel(query: _query.trim()),
    );
  }
}

// ── Suggestions ───────────────────────────────────────────────
class _SuggestionsPanel extends StatelessWidget {
  final void Function(String) onTap;
  const _SuggestionsPanel({required this.onTap});

  static const _suggestions = [
    ('🔥', 'Trending topics', NewPalette.primary),
    ('💔', 'Relationships', Color(0xFFE85580)),
    ('🧠', 'Mental Health', Color(0xFF9C27B0)),
    ('💼', 'Career vents', Color(0xFF009688)),
    ('😂', 'Dark Humor', Color(0xFFFFC107)),
    ('🙈', 'Confessions', Color(0xFFFF5722)),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'BROWSE',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: NewPalette.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: AppConstants.defaultCommunities.length,
            itemBuilder: (ctx, i) {
              final c = AppConstants.defaultCommunities[i];
              final color = Color(c['color'] as int);
              return GestureDetector(
                onTap: () => onTap(c['name'] as String),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: NewPalette.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: color.withOpacity(0.35), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Text(c['icon'] as String,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        c['name'] as String,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'POPULAR SEARCHES',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: NewPalette.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        ..._suggestions.asMap().entries.map((e) {
          final (emoji, label, color) = e.value;
          return GestureDetector(
            onTap: () => onTap('$emoji $label'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: NewPalette.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NewPalette.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: NewPalette.white,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.north_west_rounded,
                      size: 14, color: NewPalette.textMuted),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: e.key * 45))
                .fadeIn(duration: 280.ms)
                .slideX(begin: 0.04, end: 0),
          );
        }),
      ],
    );
  }
}

// ── Results panel ─────────────────────────────────────────────
class _ResultsPanel extends ConsumerWidget {
  final String query;
  const _ResultsPanel({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider(query));

    return resultsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: NewPalette.primary)),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.redAccent))),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: NewPalette.cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: NewPalette.border),
                  ),
                  child: const Center(
                      child: Text('🔍', style: TextStyle(fontSize: 40))),
                ),
                const SizedBox(height: 20),
                Text(
                  'No results for "$query"',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: NewPalette.white,
                  ),
                ),
                const SizedBox(height: 8),
                Color(0xFFB5B5B5)
                    .withOpacity(0.7)
                    .textWrapper('Try different keywords'),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: NewPalette.background,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: NewPalette.primarySoft,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: NewPalette.primary.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      '${posts.length} results',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        color: NewPalette.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('for "$query"',
                      style:
                          TextStyle(fontSize: 12, color: NewPalette.textMuted)),
                ],
              ),
            ),
            Container(height: 1, color: NewPalette.border),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 40),
                itemCount: posts.length,
                itemBuilder: (ctx, i) => PostCard(post: posts[i], index: i),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Inline fallback utilities
extension ExtensionText on Color {
  Widget textWrapper(String raw) =>
      Text(raw, style: TextStyle(color: this, fontSize: 13));
}
