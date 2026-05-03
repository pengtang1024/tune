import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/router/route_observer.dart';
import 'package:tune/core/router/widgets/responsive_shell.dart';
import 'package:tune/ui/core/settings/widgets/settings_page.dart';
import 'package:tune/ui/home/widgets/home_page.dart';
import 'package:tune/ui/library/widgets/library_page.dart';
import 'package:tune/ui/notifications/widgets/grouped_notification_list.dart';
import 'package:tune/ui/player/widgets/player_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final menuObserver = MenuRouteObserver(ref);

  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        observers: [menuObserver],
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
        ],
      ),
    ],
  );
});
