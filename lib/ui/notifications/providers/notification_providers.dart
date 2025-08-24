import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/notifications/states/notification_state_notifier.dart';
import 'package:tune/ui/notifications/states/notification_state.dart';
import 'package:tune/data/services/providers/notification_manager_provider.dart';

/// 通知状态管理器提供商
final notificationStateNotifierProvider = StateNotifierProvider<NotificationStateNotifier, NotificationState>(
      (ref) {
        // 获取通知管理器实例
        final notificationManager = ref.read(notificationManagerProvider);
        // 创建并返回通知状态管理器
        return NotificationStateNotifier(notificationManager);
      },
    );
