import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/notifications/states/notification_state.dart';
import 'package:tune/utils/logger.dart';
import 'package:tune/core/services/notification_manager.dart' as notification_manager;

/// 通知模块状态管理器
class NotificationStateNotifier extends StateNotifier<NotificationState> {
  // 用于更新AppBar未读通知数量的回调
  void Function(int)? _updateAppBarUnreadCount;
  
  // 通知管理器
  final notification_manager.NotificationManager _notificationManager;

  NotificationStateNotifier(this._notificationManager) : super(NotificationState.initial()) {
    // 构造函数中初始化
    initialize();
  }

  /// 设置更新AppBar未读通知数量的回调
  void setUpdateAppBarUnreadCountCallback(void Function(int) callback) {
    _updateAppBarUnreadCount = callback;
    // 设置回调后立即更新一次
    _updateAppBarUnreadCount?.call(state.unreadCount);
  }

  /// 转换通知类型枚举
  /// 从NotificationData的NotificationType转换为notification_manager.NotificationType
  notification_manager.NotificationType _convertToNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.important:
        return notification_manager.NotificationType.important;
      case NotificationType.system:
        return notification_manager.NotificationType.system;
      case NotificationType.message:
        return notification_manager.NotificationType.message;
      case NotificationType.update:
        return notification_manager.NotificationType.update;
      default:
        return notification_manager.NotificationType.normal;
    }
  }

  /// 初始化通知数据
  void initialize() {
    try {
      Log.info('NotificationStateNotifier: 开始初始化通知状态');
      // 这里可以添加从持久化存储加载通知的逻辑
      // 目前先添加一些示例通知
      addSampleNotifications();
      Log.info('NotificationStateNotifier: 初始化通知状态完成');
    } catch (e, stackTrace) {
      Log.error('NotificationStateNotifier: 初始化通知状态时出错: $e', stackTrace);
    }
  }

  /// 添加通知
  void addNotification(NotificationData notification) {
    try {
      Log.info('NotificationStateNotifier: 准备添加新通知: 标题=${notification.title}, 类型=${notification.type.name}');
      
      // 通过通知管理器显示通知
      _notificationManager.showNotification(
        title: notification.title,
        body: notification.content,
        type: _convertToNotificationType(notification.type),
      );
      Log.info('NotificationStateNotifier: 通知管理器处理完成');

      state = state.addNotification(notification);
      Log.info('NotificationStateNotifier: 通知添加到状态成功: ID=${notification.id}, 共有${state.notifications.length}条通知');
      
      // 更新AppBar未读通知数量
      _updateAppBarUnreadCount?.call(state.unreadCount);
      Log.info('NotificationStateNotifier: AppBar未读通知数量更新为: ${state.unreadCount}');
    } catch (e, stackTrace) {
      Log.error('NotificationStateNotifier: 添加通知时出错: $e', stackTrace);
    }
  }

  /// 标记通知为已读
  void markAsRead(int notificationId) {
    try {
      Log.info('NotificationStateNotifier: 标记通知为已读: ID=$notificationId');
      state = state.markAsRead(notificationId);
      Log.info('NotificationStateNotifier: 通知标记为已读成功: ID=$notificationId');
      
      // 更新AppBar未读通知数量
      _updateAppBarUnreadCount?.call(state.unreadCount);
      Log.info('NotificationStateNotifier: AppBar未读通知数量更新为: ${state.unreadCount}');
    } catch (e, stackTrace) {
      Log.error('NotificationStateNotifier: 标记通知为已读时出错: $e', stackTrace);
    }
  }

  /// 标记所有通知为已读
  void markAllAsRead() {
    try {
      Log.info('NotificationStateNotifier: 标记所有通知为已读');
      state = state.markAllAsRead();
      Log.info('NotificationStateNotifier: 所有通知标记为已读成功');
      
      // 更新AppBar未读通知数量
      _updateAppBarUnreadCount?.call(state.unreadCount);
      Log.info('NotificationStateNotifier: AppBar未读通知数量更新为: ${state.unreadCount}');
    } catch (e, stackTrace) {
      Log.error('NotificationStateNotifier: 标记所有通知为已读时出错: $e', stackTrace);
    }
  }

  /// 删除通知
  Future<void> removeNotification(int notificationId) async {
    try {
      Log.info('NotificationStateNotifier: 删除通知: ID=$notificationId');
      
      // 先尝试通过通知管理器取消系统通知
      await _notificationManager.cancelNotification(notificationId);
      
      // 然后从状态中移除通知
      state = state.removeNotification(notificationId);
      Log.info('NotificationStateNotifier: 通知删除成功: ID=$notificationId');
      
      // 更新AppBar未读通知数量
      _updateAppBarUnreadCount?.call(state.unreadCount);
      Log.info('NotificationStateNotifier: AppBar未读通知数量更新为: ${state.unreadCount}');
    } catch (e, stackTrace) {
      Log.error('NotificationStateNotifier: 删除通知时出错: $e', stackTrace);
      // 即使取消系统通知失败，也尝试从状态中移除
      try {
        state = state.removeNotification(notificationId);
        _updateAppBarUnreadCount?.call(state.unreadCount);
      } catch (innerError) {
        Log.error('NotificationStateNotifier: 从状态中移除通知时也出错: $innerError');
      }
    }
  }

  /// 清空所有通知
  Future<void> clearAll() async {
    try {
      Log.info('NotificationStateNotifier: 清空所有通知');
      
      // 先尝试通过通知管理器取消所有系统通知
      await _notificationManager.cancelAllNotifications();
      
      // 然后清空状态中的所有通知
      state = state.clearAll();
      Log.info('NotificationStateNotifier: 所有通知清空成功');
      
      // 更新AppBar未读通知数量
      _updateAppBarUnreadCount?.call(state.unreadCount);
      Log.info('NotificationStateNotifier: AppBar未读通知数量更新为: ${state.unreadCount}');
    } catch (e, stackTrace) {
      Log.error('NotificationStateNotifier: 清空所有通知时出错: $e', stackTrace);
      // 即使取消系统通知失败，也尝试清空状态
      try {
        state = state.clearAll();
        _updateAppBarUnreadCount?.call(state.unreadCount);
      } catch (innerError) {
        Log.error('NotificationStateNotifier: 清空状态中通知时也出错: $innerError');
      }
    }
  }
  
  /// 添加定时通知
  Future<void> addScheduledNotification({
    required String title,
    required String content,
    required DateTime scheduledTime,
    NotificationType type = NotificationType.normal,
    IconData icon = Icons.alarm,
  }) async {
    try {
      Log.info('NotificationStateNotifier: 准备添加定时通知: 标题=$title, 时间=${scheduledTime.toIso8601String()}');
      
      // 生成唯一ID
      final int id = state.notifications.isEmpty 
          ? 1 
          : state.notifications.last.id + 1;
          
      // 通过通知管理器设置定时通知
      await _notificationManager.scheduleNotification(
        title: title,
        body: content,
        scheduledTime: scheduledTime,
        type: _convertToNotificationType(type),
      );
      Log.info('NotificationStateNotifier: 定时通知设置完成: ID=$id');
      
      // 注意：定时通知在实际触发时才会添加到状态中
      // 这里只是记录设置了定时通知的信息
      Log.info('NotificationStateNotifier: 定时通知将在指定时间触发并显示');
    } catch (e, stackTrace) {
      Log.error('NotificationStateNotifier: 添加定时通知时出错: $e', stackTrace);
    }
  }

  /// 模拟添加一些示例通知（用于测试）
  void addSampleNotifications() {
    try {
      Log.info('NotificationStateNotifier: 添加示例通知');
      // 添加一些示例通知
      addNotification(
        NotificationData(
          id: 1,
          title: '欢迎使用Tune',
          content: '感谢您选择Tune音乐播放器，祝您享受美好的音乐时光！',
          type: NotificationType.system,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          icon: Icons.music_note,
        ),
      );

      addNotification(
        NotificationData(
          id: 2,
          title: '新歌推荐',
          content: '发现您可能喜欢的新歌：《夏日旋律》',
          type: NotificationType.normal,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          icon: Icons.recommend,
        ),
      );

      addNotification(
        NotificationData(
          id: 3,
          title: '播放列表更新',
          content: '您的"最爱"播放列表已更新，新增3首歌曲',
          type: NotificationType.important,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          icon: Icons.playlist_play,
        ),
      );
      
      // 添加消息通知示例
      addNotification(
        NotificationData(
          id: 4,
          title: '新消息',
          content: '用户"音乐爱好者"评论了您的分享：这首歌真好听！',
          type: NotificationType.message,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          icon: Icons.message,
        ),
      );
      
      // 添加更新通知示例
      addNotification(
        NotificationData(
          id: 5,
          title: '新版本可用',
          content: 'Tune 2.1.0版本已发布，修复了多项问题并优化了性能',
          type: NotificationType.update,
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          icon: Icons.system_update,
        ),
      );
      
      // 添加一个10秒后触发的定时通知示例
      final scheduledTime = DateTime.now().add(const Duration(seconds: 10));
      addScheduledNotification(
        title: '定时通知示例',
        content: '这是一个10秒后触发的定时通知',
        scheduledTime: scheduledTime,
        type: NotificationType.normal,
        icon: Icons.alarm,
      );
      
      Log.info('NotificationStateNotifier: 示例通知添加完成');
    } catch (e, stackTrace) {
      Log.error('NotificationStateNotifier: 添加示例通知时出错: $e', stackTrace);
    }
  }
}
