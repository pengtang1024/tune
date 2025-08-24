import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/router/route_observer.dart';
import 'package:tune/core/router/widgets/responsive_shell.dart';
import 'package:tune/ui/core/settings/widgets/settings_page.dart';
import 'package:tune/ui/featured/widgets/featured_page.dart';
import 'package:tune/ui/home/widgets/home_page.dart';
import 'package:tune/ui/library/widgets/library_page.dart';
import 'package:tune/ui/library/widgets/music_scan_page.dart';
import 'package:tune/ui/notifications/widgets/grouped_notification_list.dart';
import 'package:tune/ui/player/widgets/player_page.dart';
import 'package:tune/ui/recommend/widgets/recommend_page.dart';
import 'package:tune/ui/notifications/widgets/notification_test_page.dart';

/// 路由Provider：提供GoRouter实例
/// 路由Provider：适配go_router 16.1.0
final routerProvider = Provider<GoRouter>((ref) {
  // 此处的ref是ProviderRef，可直接传递给MenuRouteObserver
  final menuObserver = MenuRouteObserver(ref);
  // 创建一个全局的GoRouter实例

  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        // 不添加navigatorKey以避免GlobalKey重复使用问题
        observers: [menuObserver],
        builder: (context, state, child) => ResponsiveShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: '/', // name: 'home',
            builder: (BuildContext context, GoRouterState state) {
              return const HomePage();
            },
          ),
          GoRoute(
            path: '/home',
            name: '/home', // name: 'home',
            builder: (BuildContext context, GoRouterState state) {
              return const HomePage();
            },
          ),
          GoRoute(
            path: '/recommend',
            name: '/recommend', // name: 'recommend',
            builder: (BuildContext context, GoRouterState state) {
              return const RecommendPage();
            },
          ),
          GoRoute(
            path: '/featured',
            name: '/featured',
            builder: (BuildContext context, GoRouterState state) {
              return const FeaturedPage();
            },
          ),
          GoRoute(
            path: '/library',
            name: '/library',
            builder: (BuildContext context, GoRouterState state) {
              return const LibraryPage();
            },
          ),
          GoRoute(
            path: '/music-scan',
            name: '/music-scan',
            builder: (BuildContext context, GoRouterState state) {
              return const MusicScanPage();
            },
          ),
          GoRoute(
            path: '/settings',
            name: '/settings',
            builder: (BuildContext context, GoRouterState state) {
              return const SettingsPage();
            },
          ),
          GoRoute(
            path: '/player',
            name: '/player',
            builder: (BuildContext context, GoRouterState state) {
              return const PlayerPage();
            },
          ),
          GoRoute(
            path: '/notifications',
            name: '/notifications',
            builder: (BuildContext context, GoRouterState state) {
              return const NotificationListPageWithGrouping();
            },
          ),
          GoRoute(
            path: '/notification_test',
            name: '/notification_test',
            builder: (BuildContext context, GoRouterState state) {
              return const NotificationTestPage();
            },
          ),
        ],
      ),
    ],
  );
});
