import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/ui/notifications/widgets/notification_list_page.dart';

/// 通知按钮组件
/// 在标题栏显示通知按钮，带有未读消息角标
class NotificationButton extends ConsumerWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取AppBar状态
    final appBarState = ref.watch(appBarStateNotifierProvider);

    // 获取未读通知数量
    final int unreadCount = appBarState.unreadNotificationCount;

    return Stack(
      children: [
        // 通知图标按钮
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            // 导航到通知页面
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationListPage(),
              ),
            );
          },
        ),
        // 未读消息角标
        if (unreadCount > 0)
          Positioned(
            right: 2,
            top: 2,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
