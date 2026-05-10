import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/app_bar_providers.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  IconData _getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light: return Icons.light_mode;
      case ThemeMode.dark: return Icons.dark_mode;
      case ThemeMode.system: return Icons.auto_mode;
    }
  }

  String _getTooltip(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return '切换到深色模式';
      case ThemeMode.dark: return '切换到跟随系统';
      case ThemeMode.system: return '切换到浅色模式';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarState = ref.watch(appBarStateNotifierProvider);
    final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);

    return IconButton(
      icon: Icon(_getThemeIcon(appBarState.themeMode)),
      tooltip: _getTooltip(appBarState.themeMode),
      onPressed: () => appBarNotifier.toggleThemeMode(),
    );
  }
}
