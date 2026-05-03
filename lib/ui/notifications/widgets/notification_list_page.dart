import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/notifications/providers/notification_providers.dart';
import 'package:tune/ui/notifications/states/notification_state.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/empty_state.dart';
import 'package:tune/ui/widgets/modern_card.dart';

/// 通知列表页面
class NotificationListPage extends ConsumerWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '通知',
          style: AppDesignSystem.textTheme.titleLarge?.copyWith(
            fontWeight: AppDesignSystem.fontWeightSemiBold,
          ),
        ),
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
      return const EmptyState(
        icon: Icons.notifications_none,
        title: '暂无通知',
        subtitle: '当您收到新通知时，它们会显示在这里',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDesignSystem.spacing8),
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
    Color iconColor;
    double? borderWidth = 0;

    switch (notification.type) {
      case NotificationType.important:
        tileColor = isDarkMode
            ? colorScheme.error.withValues(alpha: 0.1)
            : colorScheme.error.withValues(alpha: 0.05);
        iconColor = AppDesignSystem.error;
        borderWidth = 2;
        break;
      case NotificationType.system:
        tileColor = isDarkMode
            ? colorScheme.primary.withValues(alpha: 0.1)
            : colorScheme.primary.withValues(alpha: 0.05);
        iconColor = AppDesignSystem.primary;
        borderWidth = 1;
        break;
      case NotificationType.message:
        tileColor = isDarkMode
            ? colorScheme.secondary.withValues(alpha: 0.1)
            : colorScheme.secondary.withValues(alpha: 0.05);
        iconColor = AppDesignSystem.secondary;
        borderWidth = 1;
        break;
      case NotificationType.update:
        tileColor = isDarkMode
            ? colorScheme.tertiary.withValues(alpha: 0.1)
            : colorScheme.tertiary.withValues(alpha: 0.05);
        iconColor = AppDesignSystem.tertiary;
        borderWidth = 1;
        break;
      case NotificationType.normal:
        tileColor = null;
        iconColor = colorScheme.onSurface.withValues(alpha: 0.7);
        break;
    }

    return ModernCard(
      margin: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacing4),
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      backgroundColor: tileColor,
      borderSide: borderWidth > 0
          ? BorderSide(color: iconColor, width: borderWidth)
          : null,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            notification.icon ?? _getDefaultIcon(notification.type),
            color: iconColor,
            size: AppDesignSystem.iconSize28,
          ),
          const SizedBox(width: AppDesignSystem.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: AppDesignSystem.textTheme.titleSmall?.copyWith(
                          fontWeight: notification.isRead
                              ? AppDesignSystem.fontWeightNormal
                              : AppDesignSystem.fontWeightBold,
                        ),
                      ),
                    ),
                    // 通知类型标签
                    Container(
                      margin: const EdgeInsets.only(left: AppDesignSystem.spacing8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDesignSystem.spacing8,
                        vertical: AppDesignSystem.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: AppDesignSystem.borderRadius8,
                      ),
                      child: Text(
                        _getNotificationTypeName(notification.type),
                        style: AppDesignSystem.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: AppDesignSystem.spacing8),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDesignSystem.spacing8),
                Text(
                  notification.content,
                  style: AppDesignSystem.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppDesignSystem.spacing4),
                Text(
                  _formatTime(notification.timestamp),
                  style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacing8),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: colorScheme.error.withValues(alpha: 0.8),
            onPressed: onDelete,
          ),
        ],
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
