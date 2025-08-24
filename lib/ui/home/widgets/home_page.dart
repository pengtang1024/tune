import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/notifications/providers/notification_providers.dart';
import 'package:tune/ui/notifications/states/notification_state.dart';

/// 欢迎页面组件
/// 显示应用的欢迎信息和标语
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用addPostFrameCallback避免在构建过程中修改状态

    // 添加测试通知的方法
    void addTestNotification(NotificationType type) {
      final notificationNotifier = ref.read(notificationStateNotifierProvider.notifier);
      String title;
      String content;
      IconData icon;

      switch (type) {
        case NotificationType.important:
          title = '重要通知';
          content = '这是一条重要通知，包含关键信息！';
          icon = Icons.warning;
          break;
        case NotificationType.system:
          title = '系统通知';
          content = '系统更新已完成，新版本提供了更多功能。';
          icon = Icons.system_update;
          break;
        case NotificationType.message:
          title = '消息通知';
          content = '您收到了一条新消息，请查看！';
          icon = Icons.message;
          break;
        case NotificationType.update:
          title = '更新通知';
          content = '应用有新版本可用，建议及时更新。';
          icon = Icons.refresh;
          break;
        case NotificationType.normal:
          title = '普通通知';
          content = '这是一条普通通知，包含一般信息。';
          icon = Icons.info;
          break;
      }

      notificationNotifier.addNotification(
        NotificationData(
          id: DateTime.now().millisecondsSinceEpoch,
          title: title,
          content: content,
          type: type,
          timestamp: DateTime.now(),
          icon: icon,
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              '欢迎使用 Tune',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '您的音乐，您的节奏',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 32),
            // 添加测试通知的按钮
            Column(
              children: [
                ElevatedButton(
                  onPressed: () => addTestNotification(NotificationType.normal),
                  child: const Text('添加普通通知'),
                ),
                ElevatedButton(
                  onPressed: () => addTestNotification(NotificationType.important),
                  child: const Text('添加重要通知'),
                ),
                ElevatedButton(
                  onPressed: () => addTestNotification(NotificationType.system),
                  child: const Text('添加系统通知'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
