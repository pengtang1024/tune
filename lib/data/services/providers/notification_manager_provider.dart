import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/services/local_notification_service.dart';
import 'package:tune/core/services/notification_manager.dart';

/// 通知管理器提供商
final notificationManagerProvider = Provider<NotificationManager>((ref) {
  // 创建本地通知服务实例
  final localNotificationService = LocalNotificationService();

  // 创建通知管理器实例
  final notificationManager = NotificationManager(localNotificationService);

  return notificationManager;
});
