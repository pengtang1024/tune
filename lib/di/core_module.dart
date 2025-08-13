import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tune/core/bloc/localization/localization_bloc.dart';
import 'package:tune/core/bloc/theme/theme_bloc.dart';
import 'package:tune/core/services/music_scanner_service.dart';

/// 核心服务注册（无平台依赖）
class CoreModule {
  /// 初始化核心模块
  static Future<void> init(GetIt getIt) async {
    // 注册本地化模块
    getIt.registerFactory(() => LocalizationBloc());

    // 注册主题模块
    getIt.registerFactory(() => ThemeBloc());

    // 注册字体模块

    // 注册本地存储模块
    final sharedPreferences = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(sharedPreferences);

    // 注册音乐扫描服务
    getIt.registerSingleton(MusicScannerService());
  }
}