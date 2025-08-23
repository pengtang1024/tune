import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/router/app_router.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/cross_platform_music_scanner_provider.dart';
import 'package:tune/providers/persistence_providers.dart';

/// 应用初始化器
class AppInitializer {
  /// 初始化应用
  static Future<void> initialize(Ref ref) async {
    // 初始化持久化服务
    await ref.read(sharedPreferencesServiceProvider).init();

    // 初始化路由
    ref.read(routerProvider);

    // 初始化音乐服务
    ref.read(crossPlatformMusicScannerProvider);

    // 初始化音频服务
    await ref.read(audioPlayerServiceProvider).init();
  }
}