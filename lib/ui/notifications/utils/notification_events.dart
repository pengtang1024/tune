import 'package:flutter/material.dart';
import 'package:tune/ui/notifications/providers/notification_providers.dart';
import 'package:tune/ui/notifications/states/notification_state.dart';

class NotificationEvents {
  static void onPlayStarted(ref, String title, String artist) {
    ref.read(notificationStateNotifierProvider.notifier).addNotification(
      NotificationData(
        title: '正在播放',
        content: '$title - $artist',
        type: NotificationType.normal,
        icon: Icons.music_note,
        timestamp: DateTime.now(),
        id: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  static void onScanCompleted(ref, int songCount) {
    ref.read(notificationStateNotifierProvider.notifier).addNotification(
      NotificationData(
        title: '扫描完成',
        content: '已扫描到 $songCount 首歌曲',
        type: NotificationType.system,
        icon: Icons.check_circle,
        timestamp: DateTime.now(),
        id: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  static void onScanStarted(ref) {
    ref.read(notificationStateNotifierProvider.notifier).addNotification(
      NotificationData(
        title: '开始扫描',
        content: '正在扫描本地音乐文件...',
        type: NotificationType.system,
        icon: Icons.refresh,
        timestamp: DateTime.now(),
        id: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  static void onSleepTimerStarted(ref, int minutes) {
    ref.read(notificationStateNotifierProvider.notifier).addNotification(
      NotificationData(
        title: '睡眠定时器',
        content: '已设置 $minutes 分钟后自动停止播放',
        type: NotificationType.normal,
        icon: Icons.timer,
        timestamp: DateTime.now(),
        id: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
