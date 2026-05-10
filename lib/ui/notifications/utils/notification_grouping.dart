import 'package:tune/ui/notifications/states/notification_state.dart';

enum NotificationGroupType { date, type }

class NotificationGroup {
  final String title;
  final List<NotificationData> notifications;
  final int unreadCount;

  NotificationGroup({required this.title, required this.notifications})
      : unreadCount = notifications.where((n) => !n.isRead).length;
}

class NotificationGrouping {
  static List<NotificationGroup> groupNotifications(
    List<NotificationData> notifications,
    NotificationGroupType groupType,
  ) {
    if (notifications.isEmpty) return [];

    final sorted = List<NotificationData>.from(notifications)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    switch (groupType) {
      case NotificationGroupType.date: return _byDate(sorted);
      case NotificationGroupType.type: return _byType(sorted);
    }
  }

  static List<NotificationGroup> _byDate(List<NotificationData> notifications) {
    final Map<String, List<NotificationData>> groups = {};
    final Map<String, String> keyToTitle = {};
    final now = DateTime.now();

    for (final notification in notifications) {
      final date = notification.timestamp;
      String key;
      String title;

      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        key = 'today';
        title = '今天';
      } else if (date.isAfter(now.subtract(const Duration(days: 1))) && date.isBefore(now)) {
        key = 'yesterday';
        title = '昨天';
      } else if (date.isAfter(now.subtract(Duration(days: now.weekday))) && date.isBefore(now.subtract(const Duration(days: 1)))) {
        key = 'this_week';
        title = '本周';
      } else if (date.year == now.year && date.month == now.month) {
        key = 'this_month';
        title = '本月';
      } else {
        key = '${date.year}-${date.month}';
        title = '${date.year}/${date.month}';
      }

      keyToTitle[key] = title;
      groups.putIfAbsent(key, () => []).add(notification);
    }

    return groups.entries
        .map((e) => NotificationGroup(title: keyToTitle[e.key] ?? e.key, notifications: e.value))
        .toList()
      ..sort((a, b) {
        const order = ['今天', '昨天', '本周', '本月'];
        final ai = order.indexOf(a.title);
        final bi = order.indexOf(b.title);
        if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
        if (ai >= 0) return -1;
        if (bi >= 0) return 1;
        return b.title.compareTo(a.title);
      });
  }

  static List<NotificationGroup> _byType(List<NotificationData> notifications) {
    final Map<NotificationType, List<NotificationData>> groups = {};
    for (final type in NotificationType.values) {
      groups[type] = [];
    }
    for (final notification in notifications) {
      groups[notification.type]!.add(notification);
    }
    const order = [NotificationType.important, NotificationType.message, NotificationType.system, NotificationType.update, NotificationType.normal];

    return groups.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => NotificationGroup(title: _typeName(e.key), notifications: e.value))
        .toList()
      ..sort((a, b) {
        final ai = order.indexWhere((t) => _typeName(t) == a.title);
        final bi = order.indexWhere((t) => _typeName(t) == b.title);
        return ai.compareTo(bi);
      });
  }

  static String _typeName(NotificationType type) {
    switch (type) {
      case NotificationType.important: return '重要通知';
      case NotificationType.system: return '系统通知';
      case NotificationType.message: return '消息通知';
      case NotificationType.update: return '更新通知';
      case NotificationType.normal: return '普通通知';
    }
  }
}
