/// 通知服务接口
/// 定义通知服务的基本功能
abstract class NotificationService {
  /// 初始化通知服务
  Future<void> initialize();

  /// 显示通知
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId = 'tune_channel',
    String? channelName = 'Tune Notifications',
    String? channelDescription = 'Notifications for Tune app',
  });

  /// 显示定时通知
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  });

  /// 取消通知
  Future<void> cancelNotification(int id);

  /// 取消所有通知
  Future<void> cancelAllNotifications();
  
  /// 获取应用图标角标数量（仅部分平台支持）
  Future<int?> getAppBadgeCount();
}
