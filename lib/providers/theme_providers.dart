import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/theme_service.dart';
import 'package:tune/providers/persistence_providers.dart';

final themeServiceProvider = Provider<ThemeService>((ref) {
  final persistenceService = ref.watch(sharedPreferencesServiceProvider);
  return ThemeService(persistenceService: persistenceService);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final ThemeService _themeService;
  ThemeModeNotifier(this._themeService) : super(ThemeMode.system) {
    state = _themeService.getThemeMode();
  }
  Future<void> updateThemeMode(ThemeMode? themeMode) async {
    if (themeMode == null) return;
    state = themeMode;
    await _themeService.saveThemeMode(themeMode);
  }
}
