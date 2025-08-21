import 'package:flutter/material.dart';
import 'package:tune/core/constants/app_preferences_constants.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/utils/logger.dart';

/// 主题服务
class ThemeService {
  final PersistenceService _persistenceService;

  ThemeService({required PersistenceService persistenceService})
    : _persistenceService = persistenceService;

  /// 保存主题模式
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    try {
      await _persistenceService.setInt(AppPreferencesConstants.themeMode, themeMode.index);
    } catch (e) {
      Log.info('Failed to save theme mode: $e'); // 应该使用本地化字符串
    }
  }

  /// 获取保存的主题模式
  ThemeMode getThemeMode() {
    try {
      final themeModeIndex = _persistenceService.getInt(
        AppPreferencesConstants.themeMode,
      );

      if (themeModeIndex == null) return ThemeMode.system;

      switch (themeModeIndex) {
        case 0:
          return ThemeMode.system;
        case 1:
          return ThemeMode.light;
        case 2:
          return ThemeMode.dark;
        default:
          return ThemeMode.system;
      }
    } catch (e) {
      Log.info('Failed to get theme mode: $e'); // 应该使用本地化字符串
      return ThemeMode.system;
    }
  }

  /// 保存音量设置
  Future<void> saveVolume(double volume) async {
    await _persistenceService.setDouble(AppPreferencesConstants.volume, volume);
  }

  /// 获取音量设置
  double getVolume() {
    return _persistenceService.getDouble(AppPreferencesConstants.volume) ?? 1.0;
  }
}
