import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 通知类型枚举
enum NotificationType {
  /// 普通通知
  normal,

  /// 重要通知
  important,

  /// 系统通知
  system,
  
  /// 消息通知
  message,
  
  /// 更新通知
  update,
}

/// 通知数据模型
class NotificationData extends Equatable {
  /// 通知ID
  final int id;

  /// 通知标题
  final String title;

  /// 通知内容
  final String content;

  /// 通知类型
  final NotificationType type;

  /// 是否已读
  final bool isRead;

  /// 通知时间
  final DateTime timestamp;

  /// 通知图标
  final IconData? icon;

  const NotificationData({
    required this.id,
    required this.title,
    required this.content,
    this.type = NotificationType.normal,
    this.isRead = false,
    required this.timestamp,
    this.icon,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    type,
    isRead,
    timestamp,
    icon,
  ];

  /// 创建已读副本
  NotificationData copyWithRead() {
    return NotificationData(
      id: id,
      title: title,
      content: content,
      type: type,
      isRead: true,
      timestamp: timestamp,
      icon: icon,
    );
  }

  /// 创建副本
  NotificationData copyWith({
    int? id,
    String? title,
    String? content,
    NotificationType? type,
    bool? isRead,
    DateTime? timestamp,
    IconData? icon,
  }) {
    return NotificationData(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
      icon: icon ?? this.icon,
    );
  }
}

/// 通知模块状态类
class NotificationState extends Equatable {
  /// 通知列表
  final List<NotificationData> notifications;

  /// 未读通知数量
  final int unreadCount;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
  });

  /// 初始状态
  factory NotificationState.initial() {
    return const NotificationState(notifications: [], unreadCount: 0);
  }

  @override
  List<Object?> get props => [notifications, unreadCount];

  /// 创建副本
  NotificationState copyWith({
    List<NotificationData>? notifications,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  /// 添加通知
  NotificationState addNotification(NotificationData notification) {
    final updatedNotifications = List<NotificationData>.from(notifications)
      ..insert(0, notification); // 新通知插入到列表开头

    final updatedUnreadCount = notification.isRead
        ? unreadCount
        : unreadCount + 1;

    return copyWith(
      notifications: updatedNotifications,
      unreadCount: updatedUnreadCount,
    );
  }

  /// 标记通知为已读
  NotificationState markAsRead(int notificationId) {
    final updatedNotifications = notifications.map((notification) {
      if (notification.id == notificationId && !notification.isRead) {
        return notification.copyWithRead();
      }
      return notification;
    }).toList();

    // 计算新的未读数量
    final updatedUnreadCount = updatedNotifications
        .where((notification) => !notification.isRead)
        .length;

    return copyWith(
      notifications: updatedNotifications,
      unreadCount: updatedUnreadCount,
    );
  }

  /// 标记所有通知为已读
  NotificationState markAllAsRead() {
    final updatedNotifications = notifications.map((notification) {
      return notification.isRead ? notification : notification.copyWithRead();
    }).toList();

    return copyWith(notifications: updatedNotifications, unreadCount: 0);
  }

  /// 删除通知
  NotificationState removeNotification(int notificationId) {
    final notificationToRemove = notifications.firstWhere(
      (notification) => notification.id == notificationId,
      orElse: () => NotificationData(
        id: -1,
        title: '',
        content: '',
        timestamp: DateTime.now(),
      ),
    );

    if (notificationToRemove.id == -1) {
      return this; // 未找到通知，返回原状态
    }

    final updatedNotifications = List<NotificationData>.from(notifications)
      ..removeWhere((notification) => notification.id == notificationId);

    final updatedUnreadCount = notificationToRemove.isRead
        ? unreadCount
        : unreadCount - 1;

    return copyWith(
      notifications: updatedNotifications,
      unreadCount: updatedUnreadCount,
    );
  }

  /// 清空所有通知
  NotificationState clearAll() {
    return const NotificationState(notifications: [], unreadCount: 0);
  }
}
