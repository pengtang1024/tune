import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/services/window_manager_service.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/cross_platform_music_scanner_provider.dart';
import 'package:tune/features/desktop/application/desktop_integration_provider.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/utils/logger.dart';

/// Initializes the small set of services required by the compact player.
///
/// Notifications, play history and other legacy side systems are intentionally
/// not started here. Their old UI is still present during the migration, but
/// they are not part of the new startup path.
class AppInitializer {
  static Future<void> initialize(Ref ref) async {
    try {
      Log.info('开始初始化应用核心服务');

      await _initPersistenceService(ref);
      await _initAudioPlayerService(ref);
      await _initMusicScannerService(ref);
      await WindowManagerService.init();
      await _initDesktopIntegration(ref);

      Log.info('应用核心服务初始化完成');
    } catch (error, stackTrace) {
      Log.error('应用初始化失败: $error', stackTrace);
      rethrow;
    }
  }

  static Future<void> _initPersistenceService(Ref ref) async {
    try {
      final persistenceService = ref.read(persistenceServiceProvider);
      await persistenceService.init();
      Log.info('持久化服务初始化成功');
    } catch (error, stackTrace) {
      Log.error('初始化持久化服务失败: $error', stackTrace);
      rethrow;
    }
  }

  static Future<void> _initAudioPlayerService(Ref ref) async {
    try {
      final audioPlayerService = ref.read(audioPlayerServiceProvider);
      await audioPlayerService.init();
      Log.info('音频播放服务初始化成功');
    } catch (error, stackTrace) {
      // Keep the shell usable even if the platform audio backend is missing.
      Log.error('初始化音频播放服务失败: $error', stackTrace);
      Log.info('音频播放服务初始化失败，但应用将继续运行');
    }
  }

  static Future<void> _initMusicScannerService(Ref ref) async {
    try {
      final scanner = ref.read(crossPlatformMusicScannerProvider);
      await scanner.init();
      Log.info('音乐扫描服务初始化成功');
    } catch (error, stackTrace) {
      Log.error('初始化音乐扫描服务失败: $error', stackTrace);
      Log.info('音乐扫描服务初始化失败，但应用将继续运行');
    }
  }

  /// Connects the player with the desktop.
  ///
  /// The media controls, the tray and the files the desktop hands over are
  /// optional: a machine without them still plays music.
  static Future<void> _initDesktopIntegration(Ref ref) async {
    try {
      await ref.read(desktopIntegrationProvider).start();
      Log.info('桌面集成初始化成功');
    } catch (error, stackTrace) {
      Log.error('初始化桌面集成失败: $error', stackTrace);
      Log.info('初始化桌面集成失败，但应用将继续运行');
    }
  }
}
