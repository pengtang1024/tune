import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tune/core/services/notification_service.dart';
import 'package:tune/utils/logger.dart';
import 'dart:io'; // 添加平台检测支持

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
        defaultActionName: '打开应用',
      );
      
      // 为Windows平台添加特定的初始化设置
      final initializationSettingsWindows = Platform.isWindows
          ? WindowsInitializationSettings(
              appName: 'Tune',
              guid: '2ec006fd-1260-4eaf-9f67-ffaf1a4b2fdc',
              appUserModelId: 'cn.iouf.tune',
            )
          : null;

      final initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        linux: initializationSettingsLinux,
        windows: initializationSettingsWindows,
      );

      // 平台特定初始化逻辑
      if (Platform.isWindows) {
        await _initializeWindowsPlatform(initializationSettings);
      } else {
        // 其他平台的正常初始化
        await _notificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
          onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
        );
        // 标记为已初始化
        _isInitialized = true;
        Log.info('LocalNotificationService: 初始化成功');
      }
      
      // 初始化完成后，处理待发送的通知
      if (_isInitialized && _pendingNotifications.isNotEmpty) {
        Log.info('LocalNotificationService: 处理${_pendingNotifications.length}条待发送的通知');
        await _processPendingNotifications();
      }
    } catch (e, stackTrace) {
      Log.error('LocalNotificationService: 初始化失败: $e', stackTrace);
      // 初始化失败时_isInitialized保持为false
    }
  }
  
  /// Windows平台特定初始化逻辑
  Future<void> _initializeWindowsPlatform(InitializationSettings settings) async {
    try {
      Log.info('LocalNotificationService: 开始Windows平台初始化');
      // 确保_notificationsPlugin实例在Windows平台上被正确初始化
      await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
      );
      // 标记为已初始化
      _isInitialized = true;
      Log.info('LocalNotificationService: Windows平台初始化成功');
    } catch (windowsError) {
        Log.error('LocalNotificationService: Windows平台初始化失败: $windowsError');
        // Windows平台上，初始化失败后不再尝试重新初始化，直接进入降级模式
        // 这样可以避免'_plugin has already been initialized'错误
        try {
          // 标记为降级模式初始化
          _isInitialized = true;
          _isFallbackMode = true;
          Log.info('LocalNotificationService: Windows平台初始化失败，使用降级模式，仅启用基本功能');
        } catch (fallbackError) {
          Log.error('LocalNotificationService: Windows平台降级模式初始化失败: $fallbackError');
        }
      }
  }
  
  /// 处理待发送的通知
  Future<void> _processPendingNotifications() async {
    final List<Map<String, dynamic>> notificationsCopy = List.from(_pendingNotifications);
    _pendingNotifications.clear();
    
    // 如果处于降级模式，清空待处理通知但不实际处理
    if (_isFallbackMode) {
      Log.info('LocalNotificationService: 处于降级模式，清空待处理通知但不实际处理');
      return;
    }
    
    for (final notification in notificationsCopy) {
      try {
        final String type = notification['type'];
        if (type == 'show') {
          await showNotification(
            id: notification['id'],
            title: notification['title'],
            body: notification['body'],
            payload: notification['payload'],
            channelId: notification['channelId'],
            channelName: notification['channelName'],
            channelDescription: notification['channelDescription'],
          );
        } else if (type == 'schedule') {
          await scheduleNotification(
            id: notification['id'],
            title: notification['title'],
            body: notification['body'],
            scheduledTime: notification['scheduledTime'],
            payload: notification['payload'],
          );
        }
      } catch (e) {
        Log.error('LocalNotificationService: 处理待发送通知失败: $e');
        // 如果处理失败，重新添加到待发送队列
        _pendingNotifications.add(notification);
      }
    }
  }

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;

  /// 处理后台通知响应
  static void onDidReceiveBackgroundNotificationResponse(
    NotificationResponse notificationResponse,
  ) {
    // 后台通知处理逻辑
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      Log.info('LocalNotificationService: 后台收到通知响应，payload: $payload');
      // 后台环境中可以执行的操作
    }
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
      // 检查是否已初始化
      if (!_isInitialized) {
        Log.info('LocalNotificationService: 尚未初始化，将通知加入待发送队列: ID=$id, 标题=$title');
        // 将通知加入待发送队列
        _pendingNotifications.add({
          'type': 'show',
          'id': id,
          'title': title,
          'body': body,
          'payload': payload,
          'channelId': channelId,
          'channelName': channelName,
          'channelDescription': channelDescription,
          'retryCount': 0,
        });
        return;
      }
      
      // 检查是否处于降级模式
      if (_isFallbackMode) {
        Log.info('LocalNotificationService: 处于降级模式，无法显示通知，仅记录: ID=$id, 标题=$title');
        // 在降级模式下，我们不尝试显示通知，但可以记录通知信息
        // 这里可以考虑将通知信息保存到持久化存储
        return;
      }
      
      Log.info('LocalNotificationService: 处理通知请求: ID=$id, 标题=$title');
      Log.info('通知渠道参数: channelId=${channelId ?? 'tune_channel'}, channelName=${channelName ?? 'Tune Notifications'}');

      // 为不同平台创建对应的通知详情
      final notificationDetails = _createNotificationDetails(
        channelId, channelName, channelDescription
      );

      Log.info('LocalNotificationService: 准备调用_notificationsPlugin.show()');
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      Log.info('LocalNotificationService: 通知显示成功: ID=$id');
    } catch (e, stackTrace) {
      Log.error('LocalNotificationService: 显示通知时出错: $e', stackTrace);
      // 如果是降级模式，不进行重试
      if (!_isFallbackMode) {
        // 尝试重试机制
        await _retryNotification(
          type: 'show',
          id: id,
          title: title,
          body: body,
          payload: payload,
          channelId: channelId,
          channelName: channelName,
          channelDescription: channelDescription,
        );
      }
    }
  }
  
  /// 创建平台特定的通知详情
  NotificationDetails _createNotificationDetails(
    String? channelId,
    String? channelName,
    String? channelDescription,
  ) {
    // Android平台通知详情
    final androidDetails = AndroidNotificationDetails(
      channelId ?? 'tune_channel',
      channelName ?? 'Tune Notifications',
      channelDescription: channelDescription ?? 'Notifications for Tune app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      enableVibration: true,
      playSound: true,
      // 添加锁屏通知可见性
      visibility: NotificationVisibility.public,
      // 支持通知渠道组
      groupKey: 'tune_notifications_group',
    );

    // iOS/macOS平台通知详情
    final darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      // 添加线程标识符用于分组
      threadIdentifier: 'tune_notifications',
    );

    // Linux平台通知详情
    final linuxDetails = LinuxNotificationDetails(
      urgency: LinuxNotificationUrgency.critical,
    );

    // Windows平台通知详情
    final windowsDetails = Platform.isWindows
        ? const WindowsNotificationDetails(
            // Windows平台特定配置
          )
        : null;

    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      linux: linuxDetails,
      windows: windowsDetails,
    );
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
      // 检查是否已初始化
      if (!_isInitialized) {
        Log.info('LocalNotificationService: 尚未初始化，将定时通知加入待发送队列: ID=$id, 标题=$title');
        // 将通知加入待发送队列
        _pendingNotifications.add({
          'type': 'schedule',
          'id': id,
          'title': title,
          'body': body,
          'scheduledTime': scheduledTime,
          'payload': payload,
          'retryCount': 0,
        });
        return;
      }
      
      // 检查是否处于降级模式
      if (_isFallbackMode) {
        Log.info('LocalNotificationService: 处于降级模式，无法设置定时通知，仅记录: ID=$id, 标题=$title');
        // 在降级模式下，不尝试设置定时通知
        return;
      }
      
      // 为各平台创建通知详情
      final notificationDetails = _createNotificationDetails(
        'tune_channel',
        'Tune Notifications',
        'Notifications for Tune app',
      );

      // 计算延迟时间
      final now = DateTime.now();
      final delay = scheduledTime.difference(now);
      
      if (delay.isNegative) {
        Log.info('LocalNotificationService: 调度时间已经过了，跳过定时通知: ID=$id, 标题=$title');
        return;
      }
      
      Log.info('LocalNotificationService: 设置定时通知: ID=$id, 标题=$title, 延迟=${delay.inSeconds}秒');
      
      // 使用Future.delayed来实现定时通知
      Future.delayed(delay, () async {
        if (_isInitialized && !_isFallbackMode) {
          try {
            await _notificationsPlugin.show(
              id,
              title,
              body,
              notificationDetails,
              payload: payload,
            );
            Log.info('LocalNotificationService: 定时通知显示成功: ID=$id');
          } catch (e) {
            Log.error('LocalNotificationService: 定时通知显示失败: $e');
            // 尝试重试机制
            await _retryNotification(
              type: 'show',
              id: id,
              title: title,
              body: body,
              payload: payload,
            );
          }
        } else {
          Log.info('LocalNotificationService: 定时通知显示时服务未初始化或处于降级模式: ID=$id');
          // 将通知重新加入待发送队列
          if (!_isFallbackMode) {
            _pendingNotifications.add({
              'type': 'show',
              'id': id,
              'title': title,
              'body': body,
              'payload': payload,
              'retryCount': 0,
            });
          }
        }
      });
    } catch (e, stackTrace) {
      Log.error('LocalNotificationService: 调度通知时出错: $e', stackTrace);
      // 如果是降级模式，不进行重试
      if (!_isFallbackMode) {
        // 尝试重试机制
        await _retryNotification(
          type: 'schedule',
          id: id,
          title: title,
          body: body,
          scheduledTime: scheduledTime,
          payload: payload,
        );
      }
    }
  }
  
  /// 通知重试机制
  Future<void> _retryNotification({
    required String type,
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    String? channelName,
    String? channelDescription,
    DateTime? scheduledTime,
    int retryCount = 0,
  }) async {
    // 检查是否超过最大重试次数
    if (retryCount >= maxRetryAttempts) {
      Log.error('LocalNotificationService: 通知$id超过最大重试次数，放弃重试');
      // 将失败的通知记录到日志或持久化存储中
      return;
    }
    
    // 增加重试计数
    retryCount++;
    Log.info('LocalNotificationService: 通知$id准备第$retryCount次重试');
    
    // 等待一段时间后重试
    await Future.delayed(const Duration(milliseconds: retryIntervalMs));
    
    try {
      if (type == 'show') {
        await showNotification(
          id: id,
          title: title,
          body: body,
          payload: payload,
          channelId: channelId,
          channelName: channelName,
          channelDescription: channelDescription,
        );
      } else if (type == 'schedule') {
        // 如果是定时通知，需要确保时间仍然有效
        if (scheduledTime != null && DateTime.now().isBefore(scheduledTime)) {
          await scheduleNotification(
            id: id,
            title: title,
            body: body,
            scheduledTime: scheduledTime,
            payload: payload,
          );
        }
      }
    } catch (e) {
      Log.error('LocalNotificationService: 通知$id第$retryCount次重试失败: $e');
      // 递归调用重试
      await _retryNotification(
        type: type,
        id: id,
        title: title,
        body: body,
        payload: payload,
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
        scheduledTime: scheduledTime,
        retryCount: retryCount,
      );
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    try {
      if (!_isInitialized) {
        Log.info('LocalNotificationService: 服务未初始化，跳过取消通知: ID=$id');
        return;
      }
      
      await _notificationsPlugin.cancel(id);
      Log.info('LocalNotificationService: 通知取消成功: ID=$id');
    } catch (e, stackTrace) {
      Log.error('LocalNotificationService: 取消通知时出错: $e', stackTrace);
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      if (!_isInitialized) {
        Log.info('LocalNotificationService: 服务未初始化，跳过取消所有通知');
        return;
      }
      
      await _notificationsPlugin.cancelAll();
      Log.info('LocalNotificationService: 所有通知取消成功');
    } catch (e, stackTrace) {
      Log.error('LocalNotificationService: 取消所有通知时出错: $e', stackTrace);
    }
  }
  
  /// 获取应用图标角标数量（支持多平台）
  @override
  Future<int?> getAppBadgeCount() async {
    try {
      // 即使服务未初始化，也尝试从shared_preferences获取角标数量
      // 这样至少可以让应用内的角标显示功能工作
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt('app_badge_count') ?? 0;
      
      if (!_isInitialized) {
        Log.info('LocalNotificationService: 服务未初始化，从本地存储获取角标数量: $count');
        return count;
      }
      
      // 不同平台获取角标数量的方法
      if (Platform.isIOS || Platform.isMacOS) {
        // iOS和macOS平台
        try {
          Log.info('LocalNotificationService: iOS/macOS获取角标数量: $count');
          return count;
        } catch (e) {
          Log.info('LocalNotificationService: iOS/macOS获取角标数量失败，降级处理: $e');
          return count;
        }
      } else if (Platform.isWindows) {
        // Windows平台
        try {
          Log.info('LocalNotificationService: Windows获取角标数量: $count');
          return count;
        } catch (e) {
          Log.info('LocalNotificationService: Windows获取角标数量失败，降级处理: $e');
          return count;
        }
      } else if (Platform.isAndroid) {
        // Android平台
        try {
          Log.info('LocalNotificationService: Android获取角标数量: $count');
          return count;
        } catch (e) {
          Log.info('LocalNotificationService: Android获取角标数量失败，降级处理: $e');
          return count;
        }
      }
      
      Log.info('LocalNotificationService: 当前平台可能不支持获取角标数量');
      return null;
    } catch (e) {
      Log.error('LocalNotificationService: 获取角标数量时出错: $e');
      return null;
    }
  }
  
  /// 设置应用图标角标数量
  /// [count] - 要显示的角标数量，如果为0则清除角标
  Future<void> setAppBadgeCount(int count) async {
    try {
      // 即使服务未初始化，也尝试保存角标数量到shared_preferences
      // 这样至少可以让应用内的角标显示功能工作
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('app_badge_count', count);
      
      if (!_isInitialized) {
        Log.info('LocalNotificationService: 服务未初始化，仅保存角标数量到本地存储');
        return;
      }
      
      if (_isFallbackMode) {
        Log.info('LocalNotificationService: 处于降级模式，跳过角标更新的通知操作');
        return;
      }
      
      // 不同平台设置角标数量的方法
      if (Platform.isIOS || Platform.isMacOS) {
        // iOS和macOS平台
        // 在新版本的flutter_local_notifications中，我们通过DarwinNotificationDetails来设置角标
        if (count > 0) {
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
            Log.info('LocalNotificationService: iOS/macOS设置角标数量成功: $count');
          } catch (e) {
            Log.error('LocalNotificationService: iOS/macOS设置角标数量失败: $e');
          }
        } else {
          // 清除角标
          final darwinDetails = DarwinNotificationDetails(
            presentBadge: true,
            badgeNumber: 0,
          );
          try {
            await _notificationsPlugin.show(
              9998,
              '',
              '',
              NotificationDetails(iOS: darwinDetails),
            );
            Log.info('LocalNotificationService: iOS/macOS清除角标成功');
          } catch (e) {
            Log.error('LocalNotificationService: iOS/macOS清除角标失败: $e');
          }
        }
      } else if (Platform.isWindows) {
        // Windows平台
        try {
          // Windows平台设置角标数量
          // 这里我们使用WindowsToast库的功能，虽然flutter_local_notifications没有直接支持
          // 我们通过通知的方式间接设置角标效果
          Log.info('LocalNotificationService: Windows设置角标数量: $count');
          
          // Windows不直接支持应用图标角标，但可以通过通知中心体现
          // 对于Windows，我们可以考虑发送一个特殊的静默通知来模拟角标效果
          if (count > 0) {
            final notificationDetails = _createNotificationDetails(
              'badge_channel',
              'Badge Notifications',
              'Used for app badge count updates',
            );
            
            // 为Windows平台创建一个特殊的通知来表示角标
            await _notificationsPlugin.show(
              9999, // 特殊ID用于角标通知
              'Tune',
              '您有$count条未读通知',
              notificationDetails,
              payload: 'badge_update',
            );
          } else {
            // 清除角标时取消特殊通知
            await _notificationsPlugin.cancel(9999);
          }
        } catch (e) {
          Log.error('LocalNotificationService: Windows设置角标数量失败: $e');
        }
      } else if (Platform.isAndroid) {
        // Android平台
        try {
          // 使用flutter_app_badger库来设置Android应用图标角标
          Log.info('LocalNotificationService: Android设置角标数量: $count');
          
          // 检查设备是否支持应用角标功能
          final bool isSupported = await FlutterAppBadger.isAppBadgeSupported();
          
          if (isSupported) {
            if (count > 0) {
              // 设置角标数量
              await FlutterAppBadger.updateBadgeCount(count);
              Log.info('LocalNotificationService: Android角标设置成功，数量为: $count');
            } else {
              // 清除角标
              await FlutterAppBadger.removeBadge();
              Log.info('LocalNotificationService: Android角标已清除');
            }
          } else {
            Log.info('LocalNotificationService: 当前Android设备不支持应用角标功能');
            
            // 对于不支持的设备，我们可以考虑发送一个特殊的通知来提醒用户
            if (count > 0) {
              final notificationDetails = _createNotificationDetails(
                'badge_channel',
                'Badge Notifications',
                'Used for app badge count updates',
              );
              
              // 为Android平台创建一个特殊的通知来表示角标
              await _notificationsPlugin.show(
                9999, // 特殊ID用于角标通知
                'Tune',
                '您有$count条未读通知',
                notificationDetails,
                payload: 'badge_update',
              );
            } else {
              // 清除角标时取消特殊通知
              await _notificationsPlugin.cancel(9999);
            }
          }
        } catch (e) {
          Log.error('LocalNotificationService: Android设置角标数量失败: $e');
        }
      }
      
    } catch (e) {
      Log.error('LocalNotificationService: 设置角标数量时出错: $e');
    }
  }

  /// 处理通知响应
  void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) {
    // 处理通知点击事件
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      Log.info('收到通知点击响应，payload: $payload');
      // 不在这里直接处理导航逻辑，避免在通知初始化阶段就尝试访问路由
      // 导航逻辑应该在应用完全初始化后由更高层组件处理
    }
  }
}
