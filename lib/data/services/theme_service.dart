import 'package:flutter/material.dart';
import 'package:tune/config/app_constants.dart';
import 'package:tune/data/services/persistence_service.dart';

/// 主题服务
class ThemeService {
  final PersistenceService _persistenceService;

  ThemeService({required PersistenceService persistenceService})
      : _persistenceService = persistenceService;

  /// 保存主题模式
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final themeModeIndex = themeMode.index;
    await _persistenceService.setString(
        AppConstants.themeMode, themeModeIndex.toString());
  }

  /// 获取保存的主题模式
  ThemeMode getThemeMode() {
    final themeModeString = _persistenceService.getString(AppConstants.themeMode);
    if (themeModeString == null) return ThemeMode.system;

    final themeModeIndex = int.tryParse(themeModeString);
    if (themeModeIndex == null) return ThemeMode.system;

    if (themeModeIndex >= 0 && themeModeIndex < ThemeMode.values.length) {
      return ThemeMode.values[themeModeIndex];
    }

    return ThemeMode.system;
  }

  /// 保存音量设置
  Future<void> saveVolume(double volume) async {
    await _persistenceService.setDouble(AppConstants.volume, volume);
  }

  /// 获取音量设置
  double getVolume() {
    return _persistenceService.getDouble(AppConstants.volume) ?? 1.0;
  }
}