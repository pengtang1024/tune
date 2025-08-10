import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:tune/core/config/app_config.dart';
import 'package:tune/di/injector.dart';

/// 应用初始化类
///
/// 负责应用启动时的各种初始化工作，包括依赖注入、配置初始化等
class AppInitializer {
  /// 初始化应用
  static Future<void> init() async {
    // 确保WidgetsBinding初始化完成
    WidgetsFlutterBinding.ensureInitialized();

    // 初始化依赖注入
    await Injector.init();

    // 初始化应用配置
    await AppConfig.init();

    // 配置错误处理
    FlutterError.onError = (details) {
      // 自定义错误处理（如上报到日志服务）
      if (kDebugMode) {
        print('生产环境错误: ${details.exception}');
      }
    };
  }
}