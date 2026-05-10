import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/notifications/providers/notification_providers.dart';
import 'package:tune/ui/notifications/states/notification_state.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/empty_state.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class NotificationListPage extends ConsumerWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Notifications',
          style: AppDesignSystem.textTheme.titleLarge?.copyWith(
            fontWeight: AppDesignSystem.fontWeightSemiBold,
          ),
        ),
        actions: [
          if (notificationState.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all, size: AppDesignSystem.iconSize24),
              onPressed: () => ref.read(notificationStateNotifierProvider.notifier).clearAll(),
              tooltip: 'Clear all',
            ),
          if (notificationState.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.mark_chat_read, size: AppDesignSystem.iconSize24),
              onPressed: () => ref.read(notificationStateNotifierProvider.notifier).markAllAsRead(),
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: NotificationList(notifications: notificationState.notifications),
    );
  }
}

class NotificationList extends ConsumerWidget {
  final List<NotificationData> notifications;
  const NotificationList({super.key, required this.notifications});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (notifications.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none,
        title: 'No notifications',
        subtitle: 'When you receive new notifications, they will appear here',
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
            if (!notification.isRead) {
              ref.read(notificationStateNotifierProvider.notifier).markAsRead(notification.id);
            }
          },
          onDelete: () {
            ref.read(notificationStateNotifierProvider.notifier).removeNotification(notification.id);
          },
        );
      },
    );
  }
}

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color? bgColor;
    Color iconColor;
    double borderW = 0;

    switch (notification.type) {
      case NotificationType.important:
        bgColor = AppDesignSystem.error.withValues(alpha: isDark ? 0.1 : 0.05);
        iconColor = AppDesignSystem.error;
        borderW = 2;
        break;
      case NotificationType.system:
        bgColor = AppDesignSystem.primary.withValues(alpha: isDark ? 0.1 : 0.05);
        iconColor = AppDesignSystem.primary;
        borderW = 1;
        break;
      case NotificationType.message:
        bgColor = AppDesignSystem.secondary.withValues(alpha: isDark ? 0.1 : 0.05);
        iconColor = AppDesignSystem.secondary;
        borderW = 1;
        break;
      case NotificationType.update:
        bgColor = AppDesignSystem.tertiary.withValues(alpha: isDark ? 0.1 : 0.05);
        iconColor = AppDesignSystem.tertiary;
        borderW = 1;
        break;
      case NotificationType.normal:
        iconColor = AppDesignSystem.neutral400;
        break;
    }

    return ModernCard(
      margin: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacing4),
      padding: const EdgeInsets.all(AppDesignSystem.spacing12),
      backgroundColor: bgColor,
      borderSide: borderW > 0 ? BorderSide(color: iconColor, width: borderW) : null,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(notification.icon ?? _defaultIcon(notification.type), color: iconColor, size: AppDesignSystem.iconSize24),
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
                          fontWeight: notification.isRead ? AppDesignSystem.fontWeightNormal : AppDesignSystem.fontWeightBold,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: AppDesignSystem.spacing8),
                      padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing8, vertical: AppDesignSystem.spacing4),
                      decoration: BoxDecoration(color: iconColor, borderRadius: AppDesignSystem.borderRadius8),
                      child: Text(_typeName(notification.type), style: AppDesignSystem.textTheme.labelSmall?.copyWith(color: Colors.white)),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8, height: 8,
                        margin: const EdgeInsets.only(left: AppDesignSystem.spacing8),
                        decoration: const BoxDecoration(color: AppDesignSystem.primary, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: AppDesignSystem.spacing8),
                Text(notification.content, style: AppDesignSystem.textTheme.bodyMedium),
                const SizedBox(height: AppDesignSystem.spacing4),
                Text(_fmtTime(notification.timestamp), style: AppDesignSystem.textTheme.bodySmall?.copyWith(color: AppDesignSystem.neutral400)),
              ],
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacing8),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppDesignSystem.error.withValues(alpha: 0.8),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  static IconData _defaultIcon(NotificationType type) {
    switch (type) {
      case NotificationType.important: return Icons.priority_high;
      case NotificationType.system: return Icons.settings;
      case NotificationType.message: return Icons.message;
      case NotificationType.update: return Icons.system_update;
      case NotificationType.normal: return Icons.notifications;
    }
  }

  static String _typeName(NotificationType type) {
    switch (type) {
      case NotificationType.important: return 'Important';
      case NotificationType.system: return 'System';
      case NotificationType.message: return 'Message';
      case NotificationType.update: return 'Update';
      case NotificationType.normal: return 'Normal';
    }
  }

  static String _fmtTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${time.month}/${time.day}';
  }
}
