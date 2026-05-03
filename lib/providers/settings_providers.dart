import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/services/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final settings = ref.read(settingsServiceProvider);
  return ThemeModeNotifier(settings);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsService _settings;

  ThemeModeNotifier(this._settings) : super(ThemeMode.system);

  void load() {
    state = _settings.getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _settings.setThemeMode(mode);
    state = mode;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  final settings = ref.read(settingsServiceProvider);
  return LocaleNotifier(settings);
});

class LocaleNotifier extends StateNotifier<Locale?> {
  final SettingsService _settings;

  LocaleNotifier(this._settings) : super(null);

  void load() {
    state = _settings.getLocale();
  }

  Future<void> setLocale(Locale locale) async {
    await _settings.setLocale(locale);
    state = locale;
  }
}
