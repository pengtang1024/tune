import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/ui/notifications/widgets/notification_list_page.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class NotificationButton extends ConsumerWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarState = ref.watch(appBarStateNotifierProvider);
    final unreadCount = appBarState.unreadNotificationCount;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, size: AppDesignSystem.iconSize24),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationListPage()),
            );
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 2, top: 2,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppDesignSystem.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: AppDesignSystem.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: AppDesignSystem.fontWeightBold,
                    fontSize: 10,
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
