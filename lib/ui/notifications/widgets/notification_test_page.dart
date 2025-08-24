import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/notifications/providers/notification_providers.dart';
import 'package:tune/ui/notifications/states/notification_state.dart';
import 'package:tune/utils/logger.dart';

/// 通知测试页面：用于手动触发和测试通知功能
class NotificationTestPage extends ConsumerWidget {
  const NotificationTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationStateNotifierProvider);
    final notificationNotifier = ref.read(notificationStateNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知测试'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 当前通知状态信息
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                    [
                      const Text(
                        '当前通知状态',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('总通知数: ${notificationState.notifications.length}'),
                      Text('未读通知数: ${notificationState.unreadCount}'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/notifications');
                        },
                        child: const Text('查看通知列表'),
                      ),
                    ],
                ),
              ),
            ),

            // 测试按钮组
            const SizedBox(height: 16),
            const Text(
              '触发测试通知',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // 添加普通通知
            ElevatedButton(
              onPressed: () {
                try {
                  final notification = NotificationData(
                    id: DateTime.now().millisecondsSinceEpoch,
                    title: '测试普通通知',
                    content: '这是一条测试普通通知，用于调试通知功能',
                    type: NotificationType.normal,
                    timestamp: DateTime.now(),
                    icon: Icons.info_outline,
                  );
                  notificationNotifier.addNotification(notification);
                  Log.info('已触发普通通知');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('普通通知已触发')),
                  );
                } catch (e) {
                  Log.error('触发普通通知失败: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('触发普通通知失败: $e')),
                  );
                }
              },
              child: const Text('添加普通通知'),
            ),

            // 添加系统通知
            ElevatedButton(
              onPressed: () {
                try {
                  final notification = NotificationData(
                    id: DateTime.now().millisecondsSinceEpoch,
                    title: '测试系统通知',
                    content: '这是一条测试系统通知，用于调试通知功能',
                    type: NotificationType.system,
                    timestamp: DateTime.now(),
                    icon: Icons.settings,
                  );
                  notificationNotifier.addNotification(notification);
                  Log.info('已触发系统通知');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('系统通知已触发')),
                  );
                } catch (e) {
                  Log.error('触发系统通知失败: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('触发系统通知失败: $e')),
                  );
                }
              },
              child: const Text('添加系统通知'),
            ),

            // 添加重要通知
            ElevatedButton(
              onPressed: () {
                try {
                  final notification = NotificationData(
                    id: DateTime.now().millisecondsSinceEpoch,
                    title: '测试重要通知',
                    content: '这是一条测试重要通知，用于调试通知功能',
                    type: NotificationType.important,
                    timestamp: DateTime.now(),
                    icon: Icons.warning,
                  );
                  notificationNotifier.addNotification(notification);
                  Log.info('已触发重要通知');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('重要通知已触发')),
                  );
                } catch (e) {
                  Log.error('触发重要通知失败: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('触发重要通知失败: $e')),
                  );
                }
              },
              child: const Text('添加重要通知'),
            ),

            // 添加多条示例通知
            ElevatedButton(
              onPressed: () {
                try {
                  notificationNotifier.addSampleNotifications();
                  Log.info('已触发多条示例通知');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('多条示例通知已触发')),
                  );
                } catch (e) {
                  Log.error('触发示例通知失败: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('触发示例通知失败: $e')),
                  );
                }
              },
              child: const Text('添加示例通知'),
            ),

            // 清空所有通知
            ElevatedButton(
              onPressed: () {
                try {
                  notificationNotifier.clearAll();
                  Log.info('已清空所有通知');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('所有通知已清空')),
                  );
                } catch (e) {
                  Log.error('清空通知失败: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('清空通知失败: $e')),
                  );
                }
              },
              child: const Text('清空所有通知'),
            ),

            // 标记所有为已读
            ElevatedButton(
              onPressed: () {
                try {
                  notificationNotifier.markAllAsRead();
                  Log.info('已标记所有通知为已读');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('所有通知已标记为已读')),
                  );
                } catch (e) {
                  Log.error('标记通知为已读失败: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('标记通知为已读失败: $e')),
                  );
                }
              },
              child: const Text('标记所有为已读'),
            ),
          ],
        ),
      ),
    );
  }
}