import 'package:get_it/get_it.dart';
import 'package:tune/di/core_module.dart';
import 'package:tune/di/data_module.dart';
import 'package:tune/di/platform_module.dart';
import 'package:tune/di/audio_module.dart';
import 'package:tune/di/business_module.dart';

/// 注入器入口（初始化所有模块）
class Injector {
  /// GetIt实例
  static final GetIt _getIt = GetIt.instance;

  /// 初始化所有模块
  static Future<void> init() async {
    // 初始化核心模块
    await CoreModule.init(_getIt);

    // 初始化数据模块
    await DataModule.init(_getIt);

    // 初始化音频模块
    await AudioModule.init(_getIt);

    // 初始化业务模块
    await BusinessModule.init(_getIt);

    // 初始化平台模块
    await PlatformModule.init(_getIt);
  }

  /// 获取依赖实例
  static T get<T extends Object>() {
    return _getIt.get<T>();
  }

}
