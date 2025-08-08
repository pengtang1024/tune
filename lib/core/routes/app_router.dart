import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:tune/presentation/pages/home_page.dart';
import 'package:tune/presentation/pages/player_page.dart';
import 'package:tune/presentation/pages/library_page.dart';
import 'package:tune/presentation/pages/search_page.dart';
import 'package:tune/presentation/pages/settings_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: HomeRoute.page, initial: true),
        AutoRoute(page: PlayerRoute.page),
        AutoRoute(page: LibraryRoute.page),
        AutoRoute(page: SearchRoute.page),
        AutoRoute(page: SettingsRoute.page),
      ];
}

@RoutePage(name: 'HomeRoute')
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}

@RoutePage(name: 'PlayerRoute')
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlayerPage();
  }
}

@RoutePage(name: 'LibraryRoute')
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LibraryPage();
  }
}

@RoutePage(name: 'SearchRoute')
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SearchPage();
  }
}

@RoutePage(name: 'SettingsRoute')
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPage();
  }
}