import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/app_bar_providers.dart';

/// 主题切换按钮组件
/// 负责在不同主题模式之间切换
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  /// 根据主题模式获取对应的图标
  IconData _getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.auto_mode;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarState = ref.watch(appBarStateNotifierProvider);
    final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);

    return IconButton(
      icon: Icon(_getThemeIcon(appBarState.themeMode)),
      tooltip: switch (appBarState.themeMode) {
        ThemeMode.light => '切换到深色模式',
        ThemeMode.dark => '切换到跟随系统',
        ThemeMode.system => '切换到浅色模式',
      },
      onPressed: () {
        appBarNotifier.toggleThemeMode();
      },
    );
  }
}
