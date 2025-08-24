import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/cross_platform_music_scanner_provider.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/ui/notifications/providers/notification_providers.dart';
import 'package:tune/utils/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tune/data/services/providers/notification_manager_provider.dart';
import 'dart:io'; // 用于平台检测

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
        notificationStateNotifierProvider.notifier,
      );

      // 设置更新AppBar未读通知数量的回调
      notificationNotifier.setUpdateAppBarUnreadCountCallback((count) {
        ref
            .read(appBarStateNotifierProvider.notifier)
            .updateUnreadNotificationCount(count);
      });

      notificationNotifier.initialize();

      // 获取未读通知数量并更新AppBar
      final notificationState = ref.read(notificationStateNotifierProvider);
      ref
          .read(appBarStateNotifierProvider.notifier)
          .updateUnreadNotificationCount(notificationState.unreadCount);

      Log.info('通知服务初始化成功');
    } catch (e, stackTrace) {
      Log.error('初始化通知服务失败: $e', stackTrace);
      // 不重新抛出通知服务初始化错误，避免应用启动失败
      Log.info('通知服务初始化失败，但应用将继续运行');
    }
  }

  /// 请求通知权限（跨平台兼容）
  static Future<void> _requestNotificationPermission() async {
    try {
      // 根据不同平台处理通知权限
      if (Platform.isAndroid) {
        // Android平台需要请求通知权限
        // 注意：在permission_handler 12.0.1版本中，foregroundService权限可能已更改或移除
        final notificationPermission = await Permission.notification.request();
        
        if (notificationPermission.isGranted) {
          Log.info('Android: 通知权限已授予');
          // 尝试请求前台服务权限，如果可用
          try {
            // 由于permission_handler 12.0.1版本中foregroundService权限可能不存在
            // 这里添加try-catch以避免构建错误
            // 实际应用中可能需要根据具体的permission_handler版本进行适配
          } catch (e) {
            Log.info('Android: 前台服务权限请求不可用或已更改');
          }
        } else {
          Log.info('Android: 通知权限被拒绝');
        }
      }
      else if (Platform.isIOS || Platform.isMacOS) {
        // iOS和macOS平台
        final notificationPermission = await Permission.notification.request();
        
        if (notificationPermission.isGranted) {
          Log.info('iOS/macOS: 通知权限已授予');
        } else {
          Log.info('iOS/macOS: 通知权限被拒绝');
        }
      }
      else if (Platform.isWindows) {
        // Windows平台
        // Windows通常不需要显式请求通知权限，但需要确保应用已注册通知
        Log.info('Windows: 初始化通知服务，Windows平台通常不需要显式请求权限');
        // Windows特定的通知初始化逻辑可以在这里添加
      }
      else if (Platform.isLinux) {
        // Linux平台
        Log.info('Linux: 初始化通知服务');
        // Linux特定的通知初始化逻辑可以在这里添加
      }
      else {
        // 其他平台
        final notificationPermission = await Permission.notification.request();
        
        if (notificationPermission.isGranted) {
          Log.info('其他平台: 通知权限已授予');
        } else {
          Log.info('其他平台: 通知权限被拒绝');
        }
      }
    } catch (e, stackTrace) {
      Log.error('请求通知权限失败: $e', stackTrace);
    }
  }
}
