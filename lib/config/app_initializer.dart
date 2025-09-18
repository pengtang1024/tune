import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/cross_platform_music_scanner_provider.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/ui/notifications/providers/notification_providers.dart';
import 'package:tune/utils/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tune/data/services/providers/notification_manager_provider.dart';
import 'package:tune/data/services/providers/play_history_service_provider.dart';
import 'dart:io'; // 用于平台检测
import 'package:hive_flutter/hive_flutter.dart'; // 用于Hive初始化
import 'package:path_provider/path_provider.dart'; // 用于获取应用文档目录

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

      // 初始化通知服务
      await _initNotificationService(ref);

      Log.info('应用核心服务初始化完成');
    } catch (e, stackTrace) {
      Log.error('应用初始化失败: $e', stackTrace);
      rethrow;
    }
  }

  /// 初始化Hive
  static Future<void> _initHive() async {
    try {
      Log.info('初始化Hive');

      // 获取应用文档目录并初始化Hive
      final directory = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(directory.path);

      Log.info('Hive初始化成功');
    } catch (e, stackTrace) {
      Log.error('初始化Hive失败: $e', stackTrace);
      rethrow;
    }
  }

  /// 初始化持久化服务
  static Future<void> _initPersistenceService(Ref ref) async {
    try {
      Log.info('初始化持久化服务');

      // 初始化Hive
      await _initHive();

      final persistenceService = ref.read(sharedPreferencesServiceProvider);
      await persistenceService.init();

      // 初始化播放历史服务
      final playHistoryService = ref.read(playHistoryServiceProvider);
      await playHistoryService.init();

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
      ref.read(crossPlatformMusicScannerProvider);
      // CrossPlatformMusicScannerImpl不需要显式初始化
      Log.info('音乐扫描服务初始化成功');
    } catch (e, stackTrace) {
      Log.error('初始化音乐扫描服务失败: $e', stackTrace);
      // 不重新抛出音乐扫描服务初始化错误，避免应用启动失败
      Log.info('音乐扫描服务初始化失败，但应用将继续运行');
    }
  }

  /// 初始化通知服务
  static Future<void> _initNotificationService(Ref ref) async {
    try {
      Log.info('初始化通知服务');

      // 请求通知权限
      await _requestNotificationPermission();

      // 初始化通知管理器
      final notificationManager = ref.read(notificationManagerProvider);
      await notificationManager.initialize();

      // 初始化通知数据
      final notificationNotifier = ref.read(
          notificationStateNotifierProvider.notifier);
      notificationNotifier.initialize();

      Log.info('通知服务初始化成功');
    } catch (e, stackTrace) {
      Log.error('初始化通知服务失败: $e', stackTrace);
      // 不重新抛出通知服务初始化错误，避免应用启动失败
      Log.info('通知服务初始化失败，但应用将继续运行');
    }
  }

  /// 请求通知权限
  static Future<void> _requestNotificationPermission() async {
    try {
      Log.info('请求通知权限');
      if (Platform.isAndroid || Platform.isIOS) {
        await [
          Permission.notification,
        ].request();
      }
      Log.info('通知权限请求完成');
    } catch (e, stackTrace) {
      Log.error('请求通知权限失败: $e', stackTrace);
    }
  }
}