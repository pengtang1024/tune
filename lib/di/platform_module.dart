import 'package:get_it/get_it.dart';
import 'package:tune/core/services/platform_music_scanner_service.dart';

/// 平台服务注册（根据运行时平台动态选择）
class PlatformModule {
  /// 初始化平台模块
  static Future<void> init(GetIt getIt) async {
    // 注册平台音乐扫描服务
    getIt.registerSingleton<PlatformMusicScannerService>(
      PlatformMusicScannerServiceFactory.create(),
    );
  }
}