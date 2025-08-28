import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/notifications/providers/notification_providers.dart';
import 'package:tune/ui/notifications/states/notification_state.dart';

/// 通知列表页面
class NotificationListPage extends ConsumerWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        actions: [
          if (notificationState.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                ref.read(notificationStateNotifierProvider.notifier).clearAll();
              },
              tooltip: '清空所有通知',
            ),
          if (notificationState.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.mark_chat_read),
              onPressed: () {
                ref
                    .read(notificationStateNotifierProvider.notifier)
                    .markAllAsRead();
              },
              tooltip: '全部标记为已读',
            ),
        ],
      ),
      body: NotificationList(notifications: notificationState.notifications),
    );
  }
}

/// 通知列表组件
class NotificationList extends ConsumerWidget {
  final List<NotificationData> notifications;

  const NotificationList({super.key, required this.notifications});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无通知', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('当您收到新通知时，它们会显示在这里', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return NotificationListItem(
          notification: notification,
          onTap: () {
            // 标记为已读
            if (!notification.isRead) {
              ref
                  .read(notificationStateNotifierProvider.notifier)
                  .markAsRead(notification.id);
            }
          },
          onDelete: () {
            ref
                .read(notificationStateNotifierProvider.notifier)
                .removeNotification(notification.id);
          },
        );
      },
    );
  }
}

/// 通知列表项组件
class NotificationListItem extends StatelessWidget {
  final NotificationData notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 根据通知类型确定颜色
    Color? tileColor;
    Color? iconColor;
    double? borderWidth = 0;

    switch (notification.type) {
      case NotificationType.important:
        tileColor = isDarkMode
            ? colorScheme.error.withValues(alpha: 0.1)
            : colorScheme.error.withValues(alpha: 0.05);
        iconColor = colorScheme.error;
        borderWidth = 2;
        break;
      case NotificationType.system:
        tileColor = isDarkMode
            ? colorScheme.primary.withValues(alpha: 0.1)
            : colorScheme.primary.withValues(alpha: 0.05);
        iconColor = colorScheme.primary;
        borderWidth = 1;
        break;
      case NotificationType.message:
        tileColor = isDarkMode
            ? colorScheme.secondary.withValues(alpha: 0.1)
            : colorScheme.secondary.withValues(alpha: 0.05);
        iconColor = colorScheme.secondary;
        borderWidth = 1;
        break;
      case NotificationType.update:
        tileColor = isDarkMode
            ? colorScheme.tertiary.withValues(alpha: 0.1)
            : colorScheme.tertiary.withValues(alpha: 0.05);
        iconColor = colorScheme.tertiary;
        borderWidth = 1;
        break;
      case NotificationType.normal:
        tileColor = null;
        iconColor = colorScheme.onSurface.withValues(alpha: 0.7);
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: tileColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: iconColor, 
          width: borderWidth,
        ),
      ),
      child: ListTile(
        leading: Icon(
          notification.icon ?? _getDefaultIcon(notification.type),
          color: iconColor,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
              ),
            ),
            // 通知类型标签
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getNotificationTypeName(notification.type),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.content),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.timestamp),
              style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
            ),
          ],
        ),
        onTap: onTap,
        trailing: SizedBox(
          width: 40,
          child: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }

  /// 获取通知类型名称
  /// 获取通知类型对应的默认图标
  static IconData _getDefaultIcon(NotificationType type) {
    switch (type) {
      case NotificationType.important:
        return Icons.priority_high;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.update:
        return Icons.system_update;
      case NotificationType.normal:
        return Icons.notifications;
    }
  }
  
  /// 获取通知类型名称
  static String _getNotificationTypeName(NotificationType type) {
    switch (type) {
      case NotificationType.important:
        return '重要';
      case NotificationType.system:
        return '系统';
      case NotificationType.message:
        return '消息';
      case NotificationType.update:
        return '更新';
      case NotificationType.normal:
        return '普通';
    }
  }

  /// 格式化时间显示
  static String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}天前';
    } else {
      return '${time.month}月${time.day}日';
    }
  }
}
