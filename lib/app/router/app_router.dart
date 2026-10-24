import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/discovery/presentation/discovery_pane.dart';
import 'package:tune/features/favorites/presentation/favorites_pane.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/player/presentation/now_playing_page.dart';
import 'package:tune/features/queue/presentation/queue_panel.dart';
import 'package:tune/features/settings/presentation/settings_pane.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';
import 'package:tune/features/sources/presentation/sources_pane.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/library',
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/library' ||
          path == '/discover' ||
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
            pageBuilder: (context, state) =>
                sectionPage(state, const LibraryPane()),
          ),
          GoRoute(
            path: '/discover',
            pageBuilder: (context, state) =>
                sectionPage(state, const DiscoveryPane()),
          ),
          GoRoute(
            path: '/favorites',
            pageBuilder: (context, state) =>
                sectionPage(state, const FavoritesPane()),
          ),
          GoRoute(
            path: '/sources',
            pageBuilder: (context, state) =>
                sectionPage(state, const SourcesPane()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                sectionPage(state, const SettingsPane()),
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
          child: NowPlayingPage(
            queuePanelBuilder: (context, onClose) =>
                QueuePanel(onClose: onClose, showTransport: true),
          ),
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

/// The page of a section of the shell.
///
/// The sections fade into each other, and the fade belongs to the route. The
/// shell must not keep two pages of the router in the tree at the same time:
/// the navigator of the router carries a global key, and two of them in one
/// tree is a duplicate key — Flutter tears the tree apart for a frame, and
/// the page on the screen at that moment loses a piece of itself.
Page<void> sectionPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: CompactTokens.standardMotion,
    reverseTransitionDuration: CompactTokens.fastMotion,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
