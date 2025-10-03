import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/auth/domain/auth_controller.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/directory/presentation/directory_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/posts/presentation/post_detail_screen.dart';
import '../features/posts/domain/post.dart';
import '../features/messaging/presentation/messaging_screen.dart';
import '../features/messaging/presentation/conversation_screen.dart';
import '../features/messaging/domain/conversation.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/splash_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'home_shell.dart';
import 'router_refresh_listenable.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final authNotifier = ref.watch(authControllerProvider.notifier);

  final refreshListenable = RouterRefreshListenable(authNotifier.stream);
  ref.onDispose(refreshListenable.dispose);

  String? redirect(BuildContext context, GoRouterState state) {
    final path = state.uri.path;
    debugPrint('Router.redirect: path=$path, authState=${authState.status}');

    if (authState.isUnknown) {
      debugPrint('Router.redirect: Auth state is UNKNOWN, staying on splash');
      return path == SplashScreen.routePath ? null : SplashScreen.routePath;
    }

    if (authState.isAuthenticated) {
      debugPrint('Router.redirect: User is AUTHENTICATED');
      if (path == AuthScreen.routePath || path == OnboardingScreen.routePath || path == SplashScreen.routePath) {
        debugPrint('Router.redirect: Redirecting to FEED');
        return FeedScreen.routePath;
      }
      return null;
    }

    if (authState.isOnboarding) {
      debugPrint('Router.redirect: User needs ONBOARDING');
      if (path == OnboardingScreen.routePath) {
        return null;
      }
      return OnboardingScreen.routePath;
    }

    debugPrint('Router.redirect: User is UNAUTHENTICATED, redirecting to auth');
    final isAuthRoute = path == AuthScreen.routePath;
    final isSplash = path == SplashScreen.routePath;
    if (!isAuthRoute && !isSplash) {
      debugPrint('Router.redirect: Redirecting to AUTH screen');
      return AuthScreen.routePath;
    }
    debugPrint('Router.redirect: On splash/auth, redirecting to AUTH');
    return isSplash ? AuthScreen.routePath : null;
  }

  const bottomNavRoutes = <String>[
    FeedScreen.routePath,
    DirectoryScreen.routePath,
    MessagingScreen.routePath,
    NotificationsScreen.routePath,
    SettingsScreen.routePath,
  ];

  return GoRouter(
    debugLogDiagnostics: true,  // Enable debug logging
    initialLocation: SplashScreen.routePath,
    refreshListenable: refreshListenable,
    redirect: redirect,
    errorBuilder: (context, state) {
      debugPrint('GoRouter ERROR: ${state.error}');
      return Scaffold(
        body: Center(
          child: Text('Navigation Error: ${state.error}'),
        ),
      );
    },
    routes: [
      GoRoute(
        path: SplashScreen.routePath,
        name: SplashScreen.routeName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AuthScreen.routePath,
        name: AuthScreen.routeName,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: OnboardingScreen.routePath,
        name: OnboardingScreen.routeName,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: SearchScreen.routePath,
        name: SearchScreen.routeName,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AdminDashboardScreen.routePath,
        name: AdminDashboardScreen.routeName,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '${MessagingScreen.routePath}/:conversationId',
        name: ConversationScreen.routeName,
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final conversation = state.extra as Conversation?;
          return ConversationScreen(
            conversationId: conversationId,
            initialConversation: conversation,
          );
        },
      ),
      GoRoute(
        path: '${FeedScreen.routePath}/post/:postId',
        name: PostDetailScreen.routeName,
        builder: (context, state) {
          final post = state.extra as Post?;
          if (post == null) {
            return const Scaffold(
              body: Center(child: Text('Post not available')),
            );
          }
          return PostDetailScreen(post: post);
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          final index = bottomNavRoutes.indexWhere((route) => state.matchedLocation.startsWith(route));
          return HomeShell(
            child: child,
            currentIndex: index < 0 ? 0 : index,
            onNavigate: (selectedIndex) {
              context.go(bottomNavRoutes[selectedIndex]);
            },
          );
        },
        routes: [
          GoRoute(
            path: FeedScreen.routePath,
            name: FeedScreen.routeName,
            builder: (context, state) => const FeedScreen(),
          ),
          GoRoute(
            path: DirectoryScreen.routePath,
            name: DirectoryScreen.routeName,
            builder: (context, state) => const DirectoryScreen(),
          ),
          GoRoute(
            path: MessagingScreen.routePath,
            name: MessagingScreen.routeName,
            builder: (context, state) => const MessagingScreen(),
          ),
          GoRoute(
            path: NotificationsScreen.routePath,
            name: NotificationsScreen.routeName,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: SettingsScreen.routePath,
            name: SettingsScreen.routeName,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
