import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyThemeMode = 'theme_mode';
  static const _keyLocale = 'locale';
  static const _keyVolume = 'volume';
  static const _keyPlaySpeed = 'play_speed';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  ThemeMode getThemeMode() {
    final value = _prefs?.getString(_keyThemeMode) ?? 'system';
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }
    await _prefs?.setString(_keyThemeMode, value);
  }

  Locale? getLocale() {
    final value = _prefs?.getString(_keyLocale);
    if (value == null) return null;
    final parts = value.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts[0]);
  }

  Future<void> setLocale(Locale locale) async {
    final value = locale.countryCode != null 
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    await _prefs?.setString(_keyLocale, value);
  }

  double getVolume() {
    return _prefs?.getDouble(_keyVolume) ?? 1.0;
  }

  Future<void> setVolume(double volume) async {
    await _prefs?.setDouble(_keyVolume, volume);
  }

  double getPlaySpeed() {
    return _prefs?.getDouble(_keyPlaySpeed) ?? 1.0;
  }

  Future<void> setPlaySpeed(double speed) async {
    await _prefs?.setDouble(_keyPlaySpeed, speed);
  }
}
