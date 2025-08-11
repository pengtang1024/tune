import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/app/router/app_router.dart';
import 'package:tune/core/bloc/localization/localization_bloc.dart';
import 'package:tune/core/bloc/navigation/navigation_bloc.dart';
import 'package:tune/core/bloc/search/search_bloc.dart';
import 'package:tune/core/bloc/theme/theme_bloc.dart';
import 'package:tune/core/services/app_config_service.dart';
import 'package:tune/core/services/user_session_service.dart';
import 'package:tune/di/injector.dart';
import 'package:tune/features/audio/presentation/bloc/player/player_bloc.dart';
import 'package:tune/features/home/presentation/bloc/home_bloc.dart';

import 'app.dart';

/// 应用初始化类
///
/// 负责应用程序启动时的初始化工作，包括依赖注入、配置初始化等。
class AppInitializer {
  /// 初始化应用程序
  ///
  /// 在应用程序启动时调用，执行所有必要的初始化操作。
  static Future<void> init() async {
    // 确保Flutter框架已初始化
    WidgetsFlutterBinding.ensureInitialized();

    // 锁定设备方向为竖屏
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 初始化配置服务
    await AppConfigService.init();

    // 初始化用户会话服务
    await UserSessionService.init();

    // 初始化依赖注入
    await Injector.init();

    final appRouter = AppRouter();
    final playerBloc = Injector.get<PlayerBloc>();
    final homeBloc = Injector.get<HomeBloc>();

    // 创建应用并提供所有Bloc
    final app = MultiBlocProvider(
      providers: [
        // 提供主题Bloc
        BlocProvider<ThemeBloc>(
          create: (context) => Injector.get<ThemeBloc>(),
        ),
        // 提供本地化Bloc
        BlocProvider<LocalizationBloc>(
          create: (context) => Injector.get<LocalizationBloc>(),
        ),
        // 提供导航Bloc
        BlocProvider<NavigationBloc>(
          create: (context) => Injector.get<NavigationBloc>(),
        ),
        // 提供搜索Bloc
        BlocProvider<SearchBloc>(
          create: (context) => Injector.get<SearchBloc>(),
        ),
        // 提供播放器Bloc
        BlocProvider<PlayerBloc>(
          create: (context) => playerBloc,
        ),
        // 提供首页Bloc
        BlocProvider<HomeBloc>(
          create: (context) => homeBloc,
        ),
      ],
      child: App(appRouter: appRouter),
    );

    // 在调试模式下启用性能覆盖
    runApp(app);
  }
}
