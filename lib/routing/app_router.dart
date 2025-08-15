import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/ui/core/layout/widgets/screen_layout.dart';
import 'package:tune/ui/recommend/widgets/recommend_page.dart';
import 'package:tune/ui/featured/widgets/featured_page.dart';
import 'package:tune/ui/library/widgets/library_page.dart';
import 'package:tune/ui/core/settings/widgets/settings_page.dart';
import 'package:tune/ui/home/widgets/home_page.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return ScreenLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (BuildContext context, GoRouterState state) {
            return const HomePage();
          },
        ),
        GoRoute(
          path: '/recommend',
          name: 'recommend',
          builder: (BuildContext context, GoRouterState state) {
            return const RecommendPage();
          },
        ),
        GoRoute(
          path: '/featured',
          name: 'featured',
          builder: (BuildContext context, GoRouterState state) {
            return const FeaturedPage();
          },
        ),
        GoRoute(
          path: '/library',
          name: 'library',
          builder: (BuildContext context, GoRouterState state) {
            return const LibraryPage();
          },
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (BuildContext context, GoRouterState state) {
            return const SettingsPage();
          },
        ),
      ],
    ),
  ],
);
