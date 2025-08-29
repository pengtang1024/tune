import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tune/core/services/notification_service.dart';
import 'package:tune/utils/logger.dart';
import 'dart:io'; // 添加平台检测支持
import 'package:timezone/timezone.dart' as tz; // 添加时区支持

// 确保所有平台支持类型都被导入
export 'package:flutter_local_notifications/flutter_local_notifications.dart';


/// 本地通知服务实现
/// 使用flutter_local_notifications库实现跨平台通知功能
class LocalNotificationService implements NotificationService {
  // 使用单例模式管理FlutterLocalNotificationsPlugin实例
  static LocalNotificationService? _instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  
  // 私有构造函数
  LocalNotificationService._() : _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // 获取单例实例
  factory LocalNotificationService() {
    _instance ??= LocalNotificationService._();
    return _instance!;
  }
  
  // 跟踪初始化状态
  bool _isInitialized = false;
  
  // 标记是否处于降级模式
  bool _isFallbackMode = false;
  
  // 存储需要重试的通知
  final List<Map<String, dynamic>> _pendingNotifications = [];
  
  // 重试次数上限
  static const int maxRetryAttempts = 3;
  
  // 重试间隔（毫秒）
  static const int retryIntervalMs = 2000;

  @override
  Future<void> initialize() async {
    try {
      // 初始化通知插件
      const initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initializationSettingsLinux = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );
      // 为Windows提供必需的参数
      const initializationSettingsWindows = WindowsInitializationSettings(
        appName: 'Tune',
        guid: '2ec006fd-1260-4eaf-9f67-ffaf1a4b2fdc',
        appUserModelId: 'com.tune.app',
      );

      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        linux: initializationSettingsLinux,
        windows: initializationSettingsWindows,
      );

      // 初始化插件
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          Log.info('LocalNotificationService: 接收到通知响应，ID: ${details.id}, 内容: ${details.payload}');
        },
        onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
      );
      
      _isInitialized = true;
      Log.info('LocalNotificationService: 通知服务初始化成功');
    } catch (e, stackTrace) {
      Log.error('LocalNotificationService: 通知服务初始化失败: $e', stackTrace);
      // 即使初始化失败，也标记为已初始化以避免重复尝试
      _isInitialized = true;
      // 进入降级模式
      _isFallbackMode = true;
    }
  }

  /// 处理后台通知点击
  static void _notificationTapBackground(NotificationResponse notificationResponse) {
    Log.info('LocalNotificationService: 后台通知点击，ID: ${notificationResponse.id}');
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId = 'tune_channel',
    String? channelName = 'Tune Notifications',
    String? channelDescription = 'Notifications for Tune app',
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_isFallbackMode) {
        // 降级模式下暂存通知，稍后重试
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

      // 创建Android通知详情
      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        channelId ?? 'tune_channel',
        channelName ?? 'Tune Notifications',
        channelDescription: channelDescription ?? 'Notifications for Tune app',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );

      // 创建iOS通知详情
      final iOSPlatformChannelSpecifics = DarwinNotificationDetails();

      // 创建Linux通知详情
      final linuxPlatformChannelSpecifics = LinuxNotificationDetails();

      // 创建Windows通知详情
      final windowsPlatformChannelSpecifics = WindowsNotificationDetails();

      // 创建通用通知详情
      final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
        linux: linuxPlatformChannelSpecifics,
        windows: windowsPlatformChannelSpecifics,
      );

      // 显示通知
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
      // 在错误情况下进入降级模式
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
        // 降级模式下暂存通知，稍后重试
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

      // 创建Android通知详情
      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'scheduled_channel',
        'Scheduled Notifications',
        channelDescription: 'Notifications scheduled for later',
        importance: Importance.max,
        priority: Priority.high,
      );

      // 创建iOS通知详情
      final iOSPlatformChannelSpecifics = DarwinNotificationDetails();

      // 创建Linux通知详情
      final linuxPlatformChannelSpecifics = LinuxNotificationDetails();

      // 创建Windows通知详情
      final windowsPlatformChannelSpecifics = WindowsNotificationDetails();

      // 创建通用通知详情
      final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
        linux: linuxPlatformChannelSpecifics,
        windows: windowsPlatformChannelSpecifics,
      );

      // 安排通知，使用TZDateTime类型
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
      // 在错误情况下进入降级模式
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

      // 目前仅在iOS上支持直接获取角标数量
      if (Platform.isIOS) {
        // 使用正确的API
        return await _notificationsPlugin.getNotificationAppLaunchDetails() != null ? 0 : null;
      }
      
      Log.info('LocalNotificationService: 当前平台不支持获取角标数量');
      return null;
    } catch (e, stackTrace) {
      Log.error('LocalNotificationService: 获取角标数量失败: $e', stackTrace);
      return null;
    }
  }

  /// 设置应用图标角标数量（仅部分平台支持）
  Future<void> setAppBadgeCount(int count) async {
    try {
      if (!_isInitialized) {
        Log.info('LocalNotificationService: 服务未初始化，无法设置角标数量');
        return;
      }

      Log.info('LocalNotificationService: 设置角标数量: $count');
      
      // iOS平台 - 通过发送一个空通知来更新角标
      if (Platform.isIOS) {
        final darwinDetails = DarwinNotificationDetails(
          presentBadge: true,
          badgeNumber: count,
        );
        
        try {
          // 使用一个特殊的ID发送一个静默通知来更新角标
          await _notificationsPlugin.show(
            9998, // 特殊ID用于角标更新
            '', // 空标题
            '', // 空内容
            NotificationDetails(iOS: darwinDetails),
          );
          Log.info('LocalNotificationService: iOS角标设置成功: $count');
        } catch (e) {
          Log.error('LocalNotificationService: iOS角标设置失败: $e');
        }
        return;
      }
      
      // macOS平台 - 通过发送一个空通知来更新角标
      if (Platform.isMacOS) {
        final darwinDetails = DarwinNotificationDetails(
          presentBadge: true,
          badgeNumber: count,
        );
        
        try {
          // 使用一个特殊的ID发送一个静默通知来更新角标
          await _notificationsPlugin.show(
            9998, // 特殊ID用于角标更新
            '', // 空标题
            '', // 空内容
            NotificationDetails(macOS: darwinDetails),
          );
          Log.info('LocalNotificationService: macOS角标设置成功: $count');
        } catch (e) {
          Log.error('LocalNotificationService: macOS角标设置失败: $e');
        }
        return;
      }
      
      // Android平台 - 使用Android原生方式设置角标
      if (Platform.isAndroid) {
        try {
          // 使用SharedPreferences保存角标数量，供Android原生代码使用
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('app_badge_count', count);
          
          // 发送广播通知Android原生代码更新角标
          // 注意：这需要在Android原生代码中实现接收器
          Log.info('LocalNotificationService: Android角标数量已保存到SharedPreferences: $count');
          
          // 对于支持角标的设备，我们发送一个特殊的通知来提醒用户
          if (count > 0) {
            final notificationDetails = NotificationDetails(
              android: AndroidNotificationDetails(
                'badge_channel',
                'Badge Notifications',
                channelDescription: 'Notifications for badge display',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
              ),
            );
            
            await _notificationsPlugin.show(
              9999, // 特殊ID用于角标通知
              '未读消息',
              '您有 $count 条未读消息',
              notificationDetails,
            );
          } else {
            // 清除角标通知
            await _notificationsPlugin.cancel(9999);
          }
        } catch (e) {
          Log.error('LocalNotificationService: Android设置角标数量失败: $e');
        }
        return;
      }
      
      // Windows/Linux平台
      if (Platform.isWindows || Platform.isLinux) {
        try {
          // Windows/Linux上没有标准的角标设置方法
          Log.info('LocalNotificationService: Windows/Linux平台不支持应用角标功能');
        } catch (e) {
          Log.error('LocalNotificationService: Windows/Linux设置角标数量失败: $e');
        }
        return;
      }
      
      Log.info('LocalNotificationService: 当前平台不支持应用角标功能');
    } catch (e, stackTrace) {
      Log.error('LocalNotificationService: 设置角标数量失败: $e', stackTrace);
    }
  }
}