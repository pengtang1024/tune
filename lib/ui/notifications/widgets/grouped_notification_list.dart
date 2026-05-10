import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/notifications/providers/notification_providers.dart';
import 'package:tune/ui/notifications/states/notification_state.dart';
import 'package:tune/ui/notifications/utils/notification_grouping.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'notification_list_page.dart';

class GroupedNotificationList extends ConsumerWidget {
  final List<NotificationData> notifications;
  final NotificationGroupType groupType;

  const GroupedNotificationList({
    super.key,
    required this.notifications,
    this.groupType = NotificationGroupType.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: AppDesignSystem.neutral400),
            SizedBox(height: AppDesignSystem.spacing16),
            Text('暂无通知', style: TextStyle(fontSize: 18, color: AppDesignSystem.neutral400)),
            SizedBox(height: AppDesignSystem.spacing8),
            Text('当您收到新通知时，它们会显示在这里', style: TextStyle(color: AppDesignSystem.neutral400)),
          ],
        ),
      );
    }

    final groups = NotificationGrouping.groupNotifications(notifications, groupType);

    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, groupIndex) {
        final group = groups[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing16, vertical: AppDesignSystem.spacing8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    group.title,
                    style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                      fontWeight: AppDesignSystem.fontWeightBold,
                      color: AppDesignSystem.neutral400,
                    ),
                  ),
                  if (group.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.primary,
                        borderRadius: AppDesignSystem.borderRadius12,
                      ),
                      child: Text(
                        '${group.unreadCount} unread',
                        style: AppDesignSystem.textTheme.labelSmall?.copyWith(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.notifications.length,
              itemBuilder: (context, itemIndex) {
                final notification = group.notifications[itemIndex];
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
            ),
          ],
        );
      },
    );
  }
}

class NotificationListPageWithGrouping extends ConsumerStatefulWidget {
  const NotificationListPageWithGrouping({super.key});

  @override
  ConsumerState<NotificationListPageWithGrouping> createState() => _NotificationListPageWithGroupingState();
}

class _NotificationListPageWithGroupingState extends ConsumerState<NotificationListPageWithGrouping> {
  NotificationGroupType _currentGroupType = NotificationGroupType.date;

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '通知',
          style: AppDesignSystem.textTheme.titleLarge?.copyWith(fontWeight: AppDesignSystem.fontWeightSemiBold),
        ),
        actions: [
          PopupMenuButton<NotificationGroupType>(
            onSelected: (type) => setState(() => _currentGroupType = type),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: NotificationGroupType.date,
                child: Row(
                  children: [
                    const Text('按日期分组'),
                    if (_currentGroupType == NotificationGroupType.date)
                      const SizedBox(width: 8),
                    if (_currentGroupType == NotificationGroupType.date)
                      const Icon(Icons.check, size: 16),
                  ],
                ),
              ),
              PopupMenuItem(
                value: NotificationGroupType.type,
                child: Row(
                  children: [
                    const Text('按类型分组'),
                    if (_currentGroupType == NotificationGroupType.type)
                      const SizedBox(width: 8),
                    if (_currentGroupType == NotificationGroupType.type)
                      const Icon(Icons.check, size: 16),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.sort),
            tooltip: '分组方式',
          ),
          if (notificationState.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () => ref.read(notificationStateNotifierProvider.notifier).clearAll(),
              tooltip: '清空所有通知',
            ),
          if (notificationState.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.mark_chat_read),
              onPressed: () => ref.read(notificationStateNotifierProvider.notifier).markAllAsRead(),
              tooltip: '全部标记为已读',
            ),
        ],
      ),
      body: GroupedNotificationList(
        notifications: notificationState.notifications,
        groupType: _currentGroupType,
      ),
    );
  }
}
