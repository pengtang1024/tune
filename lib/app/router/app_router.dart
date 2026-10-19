import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/queue/presentation/queue_pane.dart';
import 'package:tune/features/settings/presentation/settings_pane.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/library',
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/library' || path == '/queue' || path == '/settings') {
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
            path: '/settings',
            builder: (context, state) => const SettingsPane(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('页面不存在'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/library'),
                child: const Text('返回音乐库'),
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
