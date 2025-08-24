import 'package:tune/ui/notifications/states/notification_state.dart';

/// 通知分组类型
enum NotificationGroupType {
  /// 按日期分组
  date,
  /// 按类型分组
  type,
}

/// 通知分组项
class NotificationGroup {
  /// 分组标题
  final String title;
  
  /// 分组中的通知列表
  final List<NotificationData> notifications;
  
  /// 分组中未读通知数量
  final int unreadCount;

  NotificationGroup({
    required this.title,
    required this.notifications,
  }) : unreadCount = notifications.where((n) => !n.isRead).length;
}

/// 通知分组工具类
class NotificationGrouping {
  /// 将通知列表按指定类型进行分组
  static List<NotificationGroup> groupNotifications(
    List<NotificationData> notifications,
    NotificationGroupType groupType,
  ) {
    if (notifications.isEmpty) {
      return [];
    }

    // 先按时间倒序排序
    final sortedNotifications = List<NotificationData>.from(notifications)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    switch (groupType) {
      case NotificationGroupType.date:
        return _groupByDate(sortedNotifications);
      case NotificationGroupType.type:
        return _groupByType(sortedNotifications);
    }
  }

  /// 按日期分组通知
  static List<NotificationGroup> _groupByDate(List<NotificationData> notifications) {
    final Map<String, List<NotificationData>> groups = {};
    final Map<String, String> keyToTitle = {}; // 存储groupKey到groupTitle的映射
    final now = DateTime.now();

    for (final notification in notifications) {
      final date = notification.timestamp;
      String groupKey;
      String groupTitle;

      // 判断日期属于哪个时间段
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        groupKey = 'today';
        groupTitle = '今天';
      } else if (
        // 昨天
        date.isAfter(now.subtract(const Duration(days: 1))) &&
        date.isBefore(now)
      ) {
        groupKey = 'yesterday';
        groupTitle = '昨天';
      } else if (
        // 本周内
        date.isAfter(now.subtract(Duration(days: now.weekday))) &&
        date.isBefore(now.subtract(const Duration(days: 1)))
      ) {
        groupKey = 'this_week';
        groupTitle = '本周';
      } else if (
        // 本月内
        date.year == now.year &&
        date.month == now.month &&
        date.day < now.day - now.weekday + 1
      ) {
        groupKey = 'this_month';
        groupTitle = '本月';
      } else {
        // 其他时间
        groupKey = '${date.year}-${date.month}';
        groupTitle = '${date.year}年${date.month}月';
      }

      // 存储groupKey到groupTitle的映射
      keyToTitle[groupKey] = groupTitle;
      
      if (!groups.containsKey(groupKey)) {
        groups[groupKey] = [];
      }
      groups[groupKey]!.add(notification);
    }
    
    // 将分组转换为NotificationGroup列表
    return groups.entries
        .map((entry) => NotificationGroup(
              title: keyToTitle[entry.key] ?? entry.key,
              notifications: entry.value,
            ))
        .toList()
        // 按时间倒序排列分组
        ..sort((a, b) {
          if (a.title == '今天') return -1;
          if (b.title == '今天') return 1;
          if (a.title == '昨天') return -1;
          if (b.title == '昨天') return 1;
          if (a.title == '本周') return -1;
          if (b.title == '本周') return 1;
          if (a.title == '本月') return -1;
          if (b.title == '本月') return 1;
          // 其他情况按年月降序排列
          final aMatch = RegExp(r'(\d+)年(\d+)月').firstMatch(a.title);
          final bMatch = RegExp(r'(\d+)年(\d+)月').firstMatch(b.title);
          if (aMatch != null && bMatch != null) {
            final aYear = int.parse(aMatch.group(1)!);
            final aMonth = int.parse(aMatch.group(2)!);
            final bYear = int.parse(bMatch.group(1)!);
            final bMonth = int.parse(bMatch.group(2)!);
            if (aYear != bYear) return bYear - aYear;
            return bMonth - aMonth;
          }
          return 0;
        });
  }

  /// 按类型分组通知
  static List<NotificationGroup> _groupByType(List<NotificationData> notifications) {
    final Map<NotificationType, List<NotificationData>> groups = {};

    // 初始化所有可能的通知类型
    for (final type in NotificationType.values) {
      groups[type] = [];
    }

    // 将通知分配到对应的类型组
    for (final notification in notifications) {
      groups[notification.type]!.add(notification);
    }

    // 将分组转换为NotificationGroup列表，过滤掉空分组
    final typeOrder = [
      NotificationType.important,
      NotificationType.message,
      NotificationType.system,
      NotificationType.update,
      NotificationType.normal,
    ];

    return groups.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => NotificationGroup(
              title: _getTypeName(entry.key),
              notifications: entry.value,
            ))
        .toList()
        // 按指定顺序排列分组
        ..sort((a, b) {
          final aIndex = typeOrder.indexWhere(
              (type) => _getTypeName(type) == a.title);
          final bIndex = typeOrder.indexWhere(
              (type) => _getTypeName(type) == b.title);
          return aIndex.compareTo(bIndex);
        });
  }

  /// 获取通知类型的显示名称
  static String _getTypeName(NotificationType type) {
    switch (type) {
      case NotificationType.important:
        return '重要通知';
      case NotificationType.system:
        return '系统通知';
      case NotificationType.message:
        return '消息通知';
      case NotificationType.update:
        return '更新通知';
      case NotificationType.normal:
        return '普通通知';
    }
  }
}