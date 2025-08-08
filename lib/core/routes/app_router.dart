import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:tune/presentation/pages/home_page.dart';
import 'package:tune/presentation/pages/player_page.dart';
import 'package:tune/presentation/pages/library_page.dart';
import 'package:tune/presentation/pages/search_page.dart';
import 'package:tune/presentation/pages/settings_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: HomeRoute.page, initial: true),
        AutoRoute(page: PlayerRoute.page),
        AutoRoute(page: LibraryRoute.page),
        AutoRoute(page: SearchRoute.page),
        AutoRoute(page: SettingsRoute.page),
      ];
}