import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/notifications/providers/notification_providers.dart';
import 'package:tune/ui/notifications/states/notification_state.dart';
import 'package:tune/ui/notifications/utils/notification_grouping.dart';
import 'notification_list_page.dart';

/// 分组通知列表组件
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
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无通知', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('当您收到新通知时，它们会显示在这里', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final groups = NotificationGrouping.groupNotifications(
      notifications,
      groupType,
    );

    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, groupIndex) {
        final group = groups[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分组标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                [
                  Text(
                    group.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  if (group.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${group.unreadCount}条未读',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 分组内的通知列表
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.notifications.length,
              itemBuilder: (context, itemIndex) {
                final notification = group.notifications[itemIndex];
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
            ),
          ],
        );
      },
    );
  }
}

/// 带分组选项的通知列表页面
class NotificationListPageWithGrouping extends ConsumerStatefulWidget {
  const NotificationListPageWithGrouping({super.key});

  @override
  ConsumerState<NotificationListPageWithGrouping> createState() =>
      _NotificationListPageWithGroupingState();
}

class _NotificationListPageWithGroupingState
    extends ConsumerState<NotificationListPageWithGrouping> {
  NotificationGroupType _currentGroupType = NotificationGroupType.date;

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        actions: [
          // 分组类型切换按钮
          PopupMenuButton<NotificationGroupType>(
            onSelected: (type) {
              setState(() {
                _currentGroupType = type;
              });
            },
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
      body: GroupedNotificationList(
        notifications: notificationState.notifications,
        groupType: _currentGroupType,
      ),
    );
  }
}