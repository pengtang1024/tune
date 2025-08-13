import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/bloc/localization/localization_bloc.dart';
import 'package:tune/core/bloc/navigation/navigation_bloc.dart';
import 'package:tune/core/bloc/search/search_bloc.dart';
import 'package:tune/core/bloc/theme/theme_bloc.dart';

// 更新导入路径到 audio 模块
import 'package:tune/features/audio/presentation/bloc/music_scan/music_scan_bloc.dart';
import 'package:tune/features/audio/presentation/bloc/player/player_bloc.dart';
import 'package:tune/features/home/presentation/bloc/home_bloc.dart';

import 'app/app.dart';
import 'app/app_initializer.dart';
import 'app/router/app_router.dart';
import 'di/injector.dart';

void main() async {
  // 初始化应用
  await AppInitializer.init();

  // 创建路由实例
  final appRouter = AppRouter();

  runApp(
    MultiBlocProvider(
      providers: [
        // 提供主题Bloc
        BlocProvider<ThemeBloc>(create: (context) => Injector.get<ThemeBloc>()),
        // 提供本地化Bloc
        BlocProvider<LocalizationBloc>(create: (context) => Injector.get<LocalizationBloc>()),
        // 提供导航Bloc
        BlocProvider<NavigationBloc>(create: (context) => Injector.get<NavigationBloc>()),
        // 提供搜索Bloc
        BlocProvider<SearchBloc>(create: (context) => Injector.get<SearchBloc>()),
        // 提供播放器Bloc
        BlocProvider<PlayerBloc>(create: (context) => Injector.get<PlayerBloc>()),
        // 提供首页Bloc
        BlocProvider<HomeBloc>(create: (context) => Injector.get<HomeBloc>()),
        // 提供音乐扫描Bloc
        BlocProvider<MusicScanBloc>(create: (context) => Injector.get<MusicScanBloc>()),
      ],
      child: App(appRouter: appRouter),
    ),
  );
}
