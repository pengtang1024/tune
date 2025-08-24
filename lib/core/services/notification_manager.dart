import 'package:tune/core/services/local_notification_service.dart';
import 'package:tune/utils/logger.dart';

/// 通知类型枚举
enum NotificationType {
  /// 普通通知
  normal,

  /// 重要通知
  important,

  /// 系统通知
  system,
  
  /// 消息通知
  message,
  
  /// 更新通知
  update,
}

/// 通知管理器
/// 负责管理应用中的所有通知，包括显示、取消、分类、角标更新等
class NotificationManager {
  final LocalNotificationService _notificationService;

  /// 通知计数器，用于生成唯一的通知ID
  int _notificationIdCounter = 0;

  /// 未读通知数量
  int _unreadCount = 0;

  NotificationManager(this._notificationService);

  /// 初始化通知管理器
  Future<void> initialize() async {
    try {
      Log.info('NotificationManager: 开始初始化');
      await _notificationService.initialize();
      Log.info('NotificationManager: 初始化成功');
      
      // 初始化时获取当前角标数量（如果支持）
      await _updateBadgeCount();
    } catch (e, stackTrace) {
      Log.error('NotificationManager: 初始化失败: $e', stackTrace);
    }
  }

  /// 获取未读通知数量
  int get unreadCount => _unreadCount;

  /// 增加未读通知数量
  void incrementUnreadCount() {
    _unreadCount++;
    _updateBadgeCount();
  }

  /// 减少未读通知数量
  void decrementUnreadCount() {
    if (_unreadCount > 0) {
      _unreadCount--;
      _updateBadgeCount();
    }
  }

  /// 重置未读通知数量
  void resetUnreadCount() {
    _unreadCount = 0;
    _updateBadgeCount();
  }
  
  /// 更新应用图标角标数量
  Future<void> _updateBadgeCount() async {
    try {
      Log.info('NotificationManager: 更新应用角标数量为: $_unreadCount');
      
      // 直接调用LocalNotificationService的setAppBadgeCount方法设置角标数量
      await _notificationService.setAppBadgeCount(_unreadCount);
      
      // 获取当前角标数量（用于验证）
      final currentBadgeCount = await _notificationService.getAppBadgeCount();
      Log.info('NotificationManager: 当前应用角标数量: $currentBadgeCount');
    } catch (e) {
      Log.error('NotificationManager: 更新角标数量时出错: $e');
    }
  }

  /// 显示通知
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationType type = NotificationType.normal,
  }) async {
    try {
      // 生成唯一的通知ID
      final int id = _notificationIdCounter++;
      Log.info('NotificationManager: 准备显示通知: ID=$id, 标题=$title, 类型=${type.name}');

      // 根据通知类型设置不同的通知参数
      String channelId = 'tune_channel';
      String channelName = 'Tune Notifications';
      String channelDescription = 'Notifications for Tune app';

      switch (type) {
        case NotificationType.important:
          channelId = 'tune_important_channel';
          channelName = 'Tune Important Notifications';
          channelDescription = 'Important notifications for Tune app';
          break;
        case NotificationType.system:
          channelId = 'tune_system_channel';
          channelName = 'Tune System Notifications';
          channelDescription = 'System notifications for Tune app';
          break;
        default:
          // 使用默认值
          break;
      }

      Log.info('NotificationManager: 通知渠道信息: channelId=$channelId, channelName=$channelName');

      // 显示通知
      await _notificationService.showNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
      );
      Log.info('NotificationManager: 通知显示成功: ID=$id');

      // 增加未读通知计数
      incrementUnreadCount();
      Log.info('NotificationManager: 未读通知计数增加到: $_unreadCount');
    } catch (e, stackTrace) {
      Log.error('NotificationManager: 显示通知时出错: $e', stackTrace);
    }
  }

  /// 显示定时通知
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    NotificationType type = NotificationType.normal,
  }) async {
    try {
      // 生成唯一的通知ID
      final int id = _notificationIdCounter++;
      Log.info('NotificationManager: 准备设置定时通知: ID=$id, 标题=$title, 时间=${scheduledTime.toIso8601String()}');

      // 显示定时通知
      await _notificationService.scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        payload: payload,
      );
      Log.info('NotificationManager: 定时通知设置成功: ID=$id');

      // 定时通知在触发时才增加未读计数
      // 这里不立即增加，因为通知还未实际显示
      Log.info('NotificationManager: 定时通知将在触发时增加未读计数');
    } catch (e, stackTrace) {
      Log.error('NotificationManager: 设置定时通知时出错: $e', stackTrace);
    }
  }

  /// 取消通知
  Future<void> cancelNotification(int id) async {
    try {
      Log.info('NotificationManager: 取消通知: ID=$id');
      await _notificationService.cancelNotification(id);
      Log.info('NotificationManager: 通知取消成功: ID=$id');
      
      // 如果是未读通知，减少未读计数
      decrementUnreadCount();
    } catch (e, stackTrace) {
      Log.error('NotificationManager: 取消通知时出错: $e', stackTrace);
    }
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    try {
      Log.info('NotificationManager: 取消所有通知');
      await _notificationService.cancelAllNotifications();
      Log.info('NotificationManager: 所有通知取消成功');
      
      // 重置未读通知计数
      resetUnreadCount();
    } catch (e, stackTrace) {
      Log.error('NotificationManager: 取消所有通知时出错: $e', stackTrace);
    }
  }
  
  /// 获取应用图标角标数量
  Future<int?> getAppBadgeCount() async {
    try {
      return await _notificationService.getAppBadgeCount();
    } catch (e) {
      Log.error('NotificationManager: 获取角标数量时出错: $e');
      return null;
    }
  }
}
