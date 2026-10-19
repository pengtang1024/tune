import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/router/route_observer.dart';
import 'package:tune/core/router/widgets/responsive_shell.dart';
import 'package:tune/ui/core/settings/widgets/settings_page.dart';
import 'package:tune/ui/home/widgets/home_page.dart';
import 'package:tune/ui/library/widgets/library_page.dart';
import 'package:tune/ui/library/widgets/search_page.dart';
import 'package:tune/ui/notifications/widgets/grouped_notification_list.dart';
import 'package:tune/ui/player/widgets/player_page.dart';

/// 未注册路由统一跳转首页，避免用户看到 404
Widget _errorBuilder(BuildContext context, GoRouterState state) {
  // 异步跳转到首页，避免在 build 阶段直接修改路由
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      context.go('/home');
    }
  });
  return const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final menuObserver = MenuRouteObserver(ref);

  return GoRouter(
    initialLocation: '/home',
    observers: [menuObserver],
    errorBuilder: _errorBuilder,
    routes: [
      ShellRoute(
        builder: (context, state, child) => ResponsiveShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/library',
            name: 'library',
            builder: (context, state) => const LibraryPage(),
          ),
          GoRoute(
            path: '/player',
            name: 'player',
            builder: (context, state) => const PlayerPage(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationListPageWithGrouping(),
          ),
          // 搜索页 — 已有 SearchPage 实现
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const SearchPage(),
          ),
          // 扫描页 → 导航到音乐库（扫描功能嵌入在 library 页面）
          GoRoute(
            path: '/scan',
            name: 'scan',
            redirect: (_, _) => '/library',
          ),
          GoRoute(
            path: '/music-scan',
            name: 'music-scan',
            redirect: (_, _) => '/library',
          ),
          // 历史页 → 导航到音乐库
          GoRoute(
            path: '/history',
            name: 'history',
            redirect: (_, _) => '/library',
          ),
          // 子路由 → 导航到音乐库
          GoRoute(
            path: '/library/songs',
            redirect: (_, _) => '/library',
          ),
          GoRoute(
            path: '/library/favorites',
            redirect: (_, _) => '/library',
          ),
          GoRoute(
            path: '/library/playlists',
            redirect: (_, _) => '/library',
          ),
          // 电台 → 导航到音乐库
          GoRoute(
            path: '/radio',
            name: 'radio',
            redirect: (_, _) => '/library',
          ),
        ],
      ),
    ],
  );
});
