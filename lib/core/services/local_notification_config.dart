import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 本地通知配置类
/// 提供各平台的通知配置
class LocalNotificationConfig {
  // 通知通道ID常量
  static const String defaultChannelId = 'tune_channel';
  static const String defaultChannelName = 'Tune Notifications';
  static const String defaultChannelDescription = 'Notifications for Tune app';
  
  static const String scheduledChannelId = 'scheduled_channel';
  static const String scheduledChannelName = 'Scheduled Notifications';
  static const String scheduledChannelDescription = 'Notifications scheduled for later';
  
  static const String badgeChannelId = 'badge_channel';
  static const String badgeChannelName = 'Badge Notifications';
  static const String badgeChannelDescription = 'Notifications for badge display';
  
  // 特殊通知ID
  static const int badgeNotificationId = 9999;
  static const int badgeUpdateNotificationId = 9998;
  
  // Android配置
  static const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );
  
  static AndroidNotificationDetails getAndroidNotificationDetails({
    String channelId = defaultChannelId,
    String channelName = defaultChannelName,
    String channelDescription = defaultChannelDescription,
    Importance importance = Importance.max,
    Priority priority = Priority.high,
    bool showWhen = false,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: priority,
      showWhen: showWhen,
    );
  }
  
  // iOS/macOS配置
  static const DarwinInitializationSettings iosInitializationSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  
  static const DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails();
  
  static DarwinNotificationDetails getIosBadgeDetails(int count) {
    return DarwinNotificationDetails(
      presentBadge: true,
      badgeNumber: count,
    );
  }
  
  // Linux配置
  static const LinuxInitializationSettings linuxInitializationSettings = LinuxInitializationSettings(
    defaultActionName: 'Open notification',
  );
  
  static const LinuxNotificationDetails linuxNotificationDetails = LinuxNotificationDetails();
  
  // Windows配置
  static const WindowsInitializationSettings windowsInitializationSettings = WindowsInitializationSettings(
    appName: 'Tune',
    guid: '2ec006fd-1260-4eaf-9f67-ffaf1a4b2fdc',
    appUserModelId: 'com.tune.app',
  );
  
  static const WindowsNotificationDetails windowsNotificationDetails = WindowsNotificationDetails();
  
  // 完整初始化配置
  static InitializationSettings get initializationSettings {
    return const InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
      linux: linuxInitializationSettings,
      windows: windowsInitializationSettings,
    );
  }
  
  // 获取通用通知详情
  static NotificationDetails getNotificationDetails({
    String channelId = defaultChannelId,
    String channelName = defaultChannelName,
    String channelDescription = defaultChannelDescription,
  }) {
    return NotificationDetails(
      android: getAndroidNotificationDetails(
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
      ),
      iOS: iosNotificationDetails,
      linux: linuxNotificationDetails,
      windows: windowsNotificationDetails,
    );
  }
  
  // 获取定时通知详情
  static NotificationDetails getScheduledNotificationDetails() {
    return NotificationDetails(
      android: getAndroidNotificationDetails(
        channelId: scheduledChannelId,
        channelName: scheduledChannelName,
        channelDescription: scheduledChannelDescription,
      ),
      iOS: iosNotificationDetails,
      linux: linuxNotificationDetails,
      windows: windowsNotificationDetails,
    );
  }
  
  // 获取角标通知详情
  static NotificationDetails getBadgeNotificationDetails() {
    return NotificationDetails(
      android: getAndroidNotificationDetails(
        channelId: badgeChannelId,
        channelName: badgeChannelName,
        channelDescription: badgeChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
  }
}