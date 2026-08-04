import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whispr/features/sparks/presentation/sparks_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/feed/presentation/home_shell.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/post/presentation/create_post_screen.dart';
import '../features/post/presentation/post_detail_screen.dart';
import '../features/community/presentation/community_screen.dart';
import '../features/community/presentation/community_detail_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/search/presentation/search_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) => GoRouter(
      navigatorKey: _rootKey,
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(
            path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

        // ── Full-screen (no bottom nav) ─────────────────────
        GoRoute(
          path: '/create',
          builder: (context, state) {
            // Extract query parameter string cleanly
            final communityId = state.uri.queryParameters['communityId'];
            return CreatePostScreen(initialCommunityId: communityId);
          },
        ),
        GoRoute(
          path: '/post/:id',
          parentNavigatorKey: _rootKey,
          builder: (_, s) => PostDetailScreen(postId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/community/:id',
          parentNavigatorKey: _rootKey,
          builder: (_, s) =>
              CommunityDetailScreen(communityId: s.pathParameters['id']!),
        ),
        GoRoute(
            path: '/reels',
            parentNavigatorKey: _rootKey,
            builder: (_, __) => const ReelsScreen()),
        GoRoute(
          path: '/search',
          parentNavigatorKey: _rootKey,
          builder: (_, s) =>
              SearchScreen(initialHashtag: s.uri.queryParameters['q']),
        ),

        // ── Shell (with bottom nav) ─────────────────────────
        ShellRoute(
          navigatorKey: _shellKey,
          builder: (_, __, child) => HomeShell(child: child),
          routes: [
            GoRoute(path: '/feed', builder: (_, __) => const FeedScreen()),
            GoRoute(
                path: '/communities',
                builder: (_, __) => const CommunityScreen()),
            GoRoute(
                path: '/notifications',
                builder: (_, __) => const NotificationsScreen()),
            GoRoute(
                path: '/profile', builder: (_, __) => const ProfileScreen()),
          ],
        ),
      ],
    ));
