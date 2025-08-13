import 'package:auto_route/auto_route.dart';
// 更新导入路径到 audio 模块
import 'package:tune/features/audio/presentation/pages/player/music_player_page.dart';
import 'package:tune/features/auth/presentation/pages/login_page.dart';
import 'package:tune/features/home/presentation/pages/home_page.dart';
import 'package:tune/features/home/presentation/pages/music_library_page.dart';
import 'package:tune/features/home/presentation/pages/music_scan_page.dart';
import 'package:tune/features/profile/presentation/pages/profile_page.dart';
import 'package:tune/features/search/presentation/pages/search_page.dart';
import 'package:tune/features/settings/presentation/pages/settings_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, initial: true),
    AutoRoute(page: MusicPlayerRoute.page),
    AutoRoute(page: MusicLibraryRoute.page),
    AutoRoute(page: SearchRoute.page),
    AutoRoute(page: SettingsRoute.page),
    AutoRoute(page: ProfileRoute.page),
    AutoRoute(page: LoginRoute.page),
    AutoRoute(page: MusicScanRoute.page),
  ];
}
