import 'package:auto_route/auto_route.dart';
import 'package:tune/features/home/presentation/pages/home/home_page.dart';
import 'package:tune/features/home/presentation/pages/library_page.dart';
import 'package:tune/features/home/presentation/pages/player/music_player_page.dart';
import 'package:tune/features/home/presentation/pages/search_page.dart';
import 'package:tune/features/home/presentation/pages/settings_page.dart';
import 'package:tune/features/home/presentation/pages/profile_page.dart';
import 'package:tune/features/home/presentation/pages/login_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, initial: true),
    AutoRoute(page: MusicPlayerRoute.page),
    AutoRoute(page: LibraryRoute.page),
    AutoRoute(page: SearchRoute.page),
    AutoRoute(page: SettingsRoute.page),
    AutoRoute(page: ProfileRoute.page),
    AutoRoute(page: LoginRoute.page),
  ];
}