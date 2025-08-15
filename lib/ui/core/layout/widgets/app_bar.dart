import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 自定义AppBar组件，提供返回按钮、标题和右侧按钮管理功能
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// AppBar标题
  final String title;

  /// 是否显示返回按钮
  final bool showBackButton;

  /// 右侧操作按钮列表
  final List<Widget>? actions;

  /// 返回按钮的自定义 onPressed 回调
  /// 如果为null，则使用默认的 Navigator.pop 或 GoRouter.pop
  final VoidCallback? onBackButtonPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.onBackButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackButtonPressed ??
                  () {
                    // 尝试使用GoRouter返回，如果失败则使用Navigator返回
                    if (GoRouter.of(context).canPop()) {
                      GoRouter.of(context).pop();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}