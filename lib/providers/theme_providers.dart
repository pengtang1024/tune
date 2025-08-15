import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/theme_service.dart';
import 'package:tune/providers/persistence_providers.dart';

/// 主题服务提供者
final themeServiceProvider = Provider<ThemeService>((ref) {
  final persistenceService = ref.watch(sharedPreferencesServiceProvider);
  return ThemeService(persistenceService: persistenceService);
});

/// 当前主题模式状态提供者
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final themeService = ref.watch(themeServiceProvider);
  return ThemeModeNotifier(themeService);
});

/// 主题模式状态管理器
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final ThemeService _themeService;

  ThemeModeNotifier(this._themeService) : super(ThemeMode.system) {
    // 初始化时从持久化存储中加载主题模式
    state = _themeService.getThemeMode();
  }

  /// 更新主题模式
  Future<void> updateThemeMode(ThemeMode? themeMode) async {
    if (themeMode == null) return;
    
    state = themeMode;
    await _themeService.saveThemeMode(themeMode);
  }
}