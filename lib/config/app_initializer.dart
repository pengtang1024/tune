import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/cross_platform_music_scanner_provider.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/utils/logger.dart';

/// 应用初始化器
class AppInitializer {
  /// 初始化应用核心服务
  static Future<void> initialize(Ref ref) async {
    try {
      Log.info('开始初始化应用核心服务');

      // 初始化持久化服务
      await _initPersistenceService(ref);

      // 初始化音频播放服务
      await _initAudioPlayerService(ref);

      // 初始化音乐扫描服务
      await _initMusicScannerService(ref);

      Log.info('应用核心服务初始化完成');
    } catch (e, stackTrace) {
      Log.error('应用初始化失败: $e', stackTrace);
      rethrow;
    }
  }

  /// 初始化持久化服务
  static Future<void> _initPersistenceService(Ref ref) async {
    try {
      Log.info('初始化持久化服务');
      final persistenceService = ref.read(sharedPreferencesServiceProvider);
      await persistenceService.init();
      Log.info('持久化服务初始化成功');
    } catch (e, stackTrace) {
      Log.error('初始化持久化服务失败: $e', stackTrace);
      rethrow;
    }
  }

  /// 初始化音频播放服务
  static Future<void> _initAudioPlayerService(Ref ref) async {
    try {
      Log.info('初始化音频播放服务');
      final audioPlayerService = ref.read(audioPlayerServiceProvider);
      await audioPlayerService.init();
      Log.info('音频播放服务初始化成功');
    } catch (e, stackTrace) {
      Log.error('初始化音频播放服务失败: $e', stackTrace);
      // 不重新抛出音频播放服务初始化错误，避免应用启动失败
      // 在Windows平台上just_audio可能存在兼容性问题
      Log.info('音频播放服务初始化失败，但应用将继续运行');
    }
  }

  /// 初始化音乐扫描服务
  static Future<void> _initMusicScannerService(Ref ref) async {
    try {
      Log.info('初始化音乐扫描服务');
      final musicScannerService = ref.read(crossPlatformMusicScannerProvider);
      // CrossPlatformMusicScannerImpl不需要显式初始化
      Log.info('音乐扫描服务初始化成功');
    } catch (e, stackTrace) {
      Log.error('初始化音乐扫描服务失败: $e', stackTrace);
      // 不重新抛出音乐扫描服务初始化错误，避免应用启动失败
      Log.info('音乐扫描服务初始化失败，但应用将继续运行');
    }
  }
}
