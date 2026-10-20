import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/favorites/presentation/favorites_pane.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/player/presentation/now_playing_page.dart';
import 'package:tune/features/queue/presentation/queue_pane.dart';
import 'package:tune/features/settings/presentation/settings_pane.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';
import 'package:tune/features/sources/presentation/sources_pane.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/library',
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/library' ||
          path == '/queue' ||
          path == '/favorites' ||
          path == '/sources' ||
          path == '/settings' ||
          path == '/now-playing') {
        return null;
      }
      // The compact player replaces the old four-tab shell. Any old deep link
      // lands on the library instead of resurrecting a removed page.
      return '/library';
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return CompactShell(currentPath: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/library',
            builder: (context, state) => const LibraryPane(),
          ),
          GoRoute(
            path: '/queue',
            builder: (context, state) => const QueuePane(),
          ),
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesPane(),
          ),
          GoRoute(
            path: '/sources',
            builder: (context, state) => const SourcesPane(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPane(),
          ),
        ],
      ),
      // The now playing view lives on the root navigator so it covers the
      // whole window instead of only the content area of the shell.
      GoRoute(
        path: '/now-playing',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          child: const NowPlayingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.loc.routerNotFoundTitle),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/library'),
                child: Text(context.loc.routerBackToLibrary),
              ),
            ],
          ),
        ),
      );
    },
  );

  ref.onDispose(router.dispose);
  return router;
});
