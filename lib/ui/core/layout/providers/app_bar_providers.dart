import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:tune/ui/core/layout/states/app_bar_state.dart';
import 'package:tune/ui/core/layout/states/app_bar_state_notifier.dart';

/// AppBar模块状态提供者
/// 集中暴露标题栏相关状态提供器（全局单例）
final appBarStateNotifierProvider = StateNotifierProvider<AppBarStateNotifier, AppBarState>(
  (ref) => AppBarStateNotifier(),
);

/// 主题模式状态提供器
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(appBarStateNotifierProvider).themeMode;
});

/// 语言状态提供器
final localeProvider = Provider<Locale>((ref) {
  return ref.watch(appBarStateNotifierProvider).locale;
});