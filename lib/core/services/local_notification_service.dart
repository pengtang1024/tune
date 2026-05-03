import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tune/core/services/notification_service.dart';
import 'package:tune/core/services/local_notification_config.dart';
import 'package:tune/utils/logger.dart';
import 'dart:io';
import 'package:timezone/timezone.dart' as tz;

export 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 本地通知服务实现
/// 使用flutter_local_notifications库实现跨平台通知功能
class LocalNotificationService implements NotificationService {
  static LocalNotificationService? _instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  
  LocalNotificationService._() : _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  factory LocalNotificationService() {
    _instance ??= LocalNotificationService._();
    return _instance!;
  }
  
  bool _isInitialized = false;
  bool _isFallbackMode = false;
  final List<Map<String, dynamic>> _pendingNotifications = [];
  static const int maxRetryAttempts = 3;
  static const int retryIntervalMs = 2000;

  @override
  Future<void> initialize() async {
    try {
      await _notificationsPlugin.initialize(
        LocalNotificationConfig.initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          Log.info('LocalNotificationService: 接收到通知响应，ID: ${details.id}, 内容: ${details.payload}');
        },
        onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
      );
      
      _isInitialized = true;
      Log.info('LocalNotificationService: 通知服务初始化成功');
    } catch (e, stackTrace) {
      Log.error('LocalNotificationService: 通知服务初始化失败: $e', stackTrace);
      _isInitialized = true;
      _isFallbackMode = true;
    }
  }

  static void _notificationTapBackground(NotificationResponse notificationResponse) {
    Log.info('LocalNotificationService: 后台通知点击，ID: ${notificationResponse.id}');
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    String? channelName,
    String? channelDescription,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_isFallbackMode) {
        _pendingNotifications.add({
          'type': 'show',
          'id': id,
          'title': title,
          'body': body,
          'payload': payload,
          'channelId': channelId,
          'channelName': channelName,
          'channelDescription': channelDescription,
        });
        Log.info('LocalNotificationService: 降级模式下暂存通知，ID: $id');
        return;
      }

      final platformChannelSpecifics = LocalNotificationConfig.getNotificationDetails(
        channelId: channelId ?? LocalNotificationConfig.defaultChannelId,
        channelName: channelName ?? LocalNotificationConfig.defaultChannelName,
        channelDescription: channelDescription ?? LocalNotificationConfig.defaultChannelDescription,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      
      Log.info('LocalNotificationService: 通知显示成功，ID: $id');
    } catch (e, stackTrace) {
      Log.error('LocalNotificationService: 显示通知失败: $e', stackTrace);
      _isFallbackMode = true;
    }
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_isFallbackMode) {
        _pendingNotifications.add({
          'type': 'schedule',
          'id': id,
          'title': title,
          'body': body,
          'scheduledTime': scheduledTime,
          'payload': payload,
        });
        Log.info('LocalNotificationService: 降级模式下暂存定时通知，ID: $id');
        return;
      }

      final platformChannelSpecifics = LocalNotificationConfig.getScheduledNotificationDetails();

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformChannelSpecifics,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      
      Log.info('LocalNotificationService: 定时通知安排成功，ID: $id');
    } catch (e, stackTrace) {
      Log.error('LocalNotificationService: 安排定时通知失败: $e', stackTrace);
      _isFallbackMode = true;
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    try {
      if (!_isInitialized) {
        Log.info('LocalNotificationService: 服务未初始化，无法取消通知');
        return;
      }

      await _notificationsPlugin.cancel(id);
      Log.info('LocalNotificationService: 通知取消成功，ID: $id');
    } catch (e, stackTrace) {
      Log.error('LocalNotificationService: 取消通知失败: $e', stackTrace);
      }
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      if (!_isInitialized) {
        Log.info('LocalNotificationService: 服务未初始化，无法取消所有通知');
        return;
      }

      await _notificationsPlugin.cancelAll();
      Log.info('LocalNotificationService: 所有通知取消成功');
    } catch (e, stackTrace) {
      Log.error('LocalNotificationService: 取消所有通知失败: $e', stackTrace);
      }
  }

  @override
  Future<int?> getAppBadgeCount() async {
    try {
      if (!_isInitialized) {
        Log.info('LocalNotificationService: 服务未初始化，无法获取角标数量');
        return null;
      }

      if (Platform.isIOS) {
        return await _notificationsPlugin.getNotificationAppLaunchDetails() != null ? 0 : null;
      }
      
      Log.info('LocalNotificationService: 当前平台不支持获取角标数量');
      return null;
    } catch (e, stackTrace) {
      Log.error('LocalNotificationService: 获取角标数量失败: $e', stackTrace);
      return null;
    }
  }

  Future<void> setAppBadgeCount(int count) async {
    try {
      if (!_isInitialized) {
        Log.info('LocalNotificationService: 服务未初始化，无法设置角标数量');
        return;
      }

      Log.info('LocalNotificationService: 设置角标数量: $count');
      
      if (Platform.isIOS) {
        await _setIosBadgeCount(count);
        return;
      }
      
      if (Platform.isMacOS) {
        await _setMacosBadgeCount(count);
        return;
      }
      
      if (Platform.isAndroid) {
        await _setAndroidBadgeCount(count);
        return;
      }
      
      if (Platform.isWindows || Platform.isLinux) {
        _logPlatformNotSupported();
        return;
      }
      
      Log.info('LocalNotificationService: 当前平台不支持应用角标功能');
    } catch (e, stackTrace) {
      Log.error('LocalNotificationService: 设置角标数量失败: $e', stackTrace);
    }
  }
  
  Future<void> _setIosBadgeCount(int count) async {
    final darwinDetails = LocalNotificationConfig.getIosBadgeDetails(count);
    
    try {
      await _notificationsPlugin.show(
        LocalNotificationConfig.badgeUpdateNotificationId,
        '',
        '',
        NotificationDetails(iOS: darwinDetails),
      );
      Log.info('LocalNotificationService: iOS角标设置成功: $count');
    } catch (e) {
      Log.error('LocalNotificationService: iOS角标设置失败: $e');
    }
  }
  
  Future<void> _setMacosBadgeCount(int count) async {
    final darwinDetails = LocalNotificationConfig.getIosBadgeDetails(count);
    
    try {
      await _notificationsPlugin.show(
        LocalNotificationConfig.badgeUpdateNotificationId,
        '',
        '',
        NotificationDetails(macOS: darwinDetails),
      );
      Log.info('LocalNotificationService: macOS角标设置成功: $count');
    } catch (e) {
      Log.error('LocalNotificationService: macOS角标设置失败: $e');
    }
  }
  
  Future<void> _setAndroidBadgeCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('app_badge_count', count);
      
      Log.info('LocalNotificationService: Android角标数量已保存到SharedPreferences: $count');
      
      if (count > 0) {
        final notificationDetails = LocalNotificationConfig.getBadgeNotificationDetails();
        
        await _notificationsPlugin.show(
          LocalNotificationConfig.badgeNotificationId,
          '未读消息',
          '您有 $count 条未读消息',
          notificationDetails,
        );
      } else {
        await _notificationsPlugin.cancel(LocalNotificationConfig.badgeNotificationId);
      }
    } catch (e) {
      Log.error('LocalNotificationService: Android设置角标数量失败: $e');
    }
  }
  
  void _logPlatformNotSupported() {
    Log.info('LocalNotificationService: Windows/Linux平台不支持应用角标功能');
  }
}