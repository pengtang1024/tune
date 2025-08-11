import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tune/core/config/font_constants.dart';
import 'package:tune/core/storage/local/local_storage_impl.dart';
import 'package:tune/core/storage/secure/secure_storage_impl.dart';

/// 应用配置服务类
///
/// 负责管理应用程序的各种配置信息，使用SharedPreferences进行本地持久化存储。
class AppConfigService {
  /// SharedPreferences实例，用于本地数据存储
  static late SharedPreferences _prefs;

  /// 本地存储实例
  static late LocalStorageImpl localStorage;

  /// 安全存储实例
  static late SecureStorageImpl secureStorage;

  /// 主题名称配置键名
  static const String _keyTheme = 'theme';

  /// 主题模式配置键名
  static const String _keyThemeMode = 'theme_mode';

  /// 语言配置键名
  static const String _keyLocale = 'locale';

  /// 字体配置键名
  static const String _keyFontFamily = 'font_family';

  /// 当前语言
  static String locale = 'en';

  /// 当前主题
  static String theme = 'trendyElectro';

  /// 当前主题模式
  static ThemeMode themeMode = ThemeMode.system;

  /// 当前字体
  static FontFamily fontFamily = FontFamily.defaultFont;

  /// 初始化配置服务
  ///
  /// 获取SharedPreferences实例，必须在应用程序启动时调用。
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    localStorage = LocalStorageImpl()..init();
    secureStorage = SecureStorageImpl()..init();

    locale = _prefs.getString(_keyLocale) ?? 'en';
    theme = _prefs.getString(_keyTheme) ?? 'trendyElectro';
    themeMode = _getThemeModeFromString(_prefs.getString(_keyThemeMode));
    final storedFont = _prefs.getString(_keyFontFamily);
    fontFamily = FontFamily.fromValue(storedFont);
  }

  /// 获取有效的主题名称
  ///
  /// 验证并返回有效的主题名称，如果存储的主题名称无效则返回默认主题
  static String getValidThemeName(String? storedTheme) {
    // 有效的主题列表
    const validThemes = ['trendyElectro', 'minimalGray', 'natureForest', 'cyberNeon', 'warmHealing'];

    // 如果存储的主题名称有效，直接返回
    if (storedTheme != null && validThemes.contains(storedTheme)) {
      return storedTheme;
    }

    // 否则返回默认主题
    return 'trendyElectro';
  }

  /// 获取主题模式枚举值
  ///
  /// 将字符串转换为ThemeMode枚举值。
  static ThemeMode _getThemeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  /// 获取主题模式字符串值
  ///
  /// 将ThemeMode枚举值转换为字符串。
  static String _getThemeModeString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// 设置主题
  static Future<void> setTheme(String themeName) async {
    theme = themeName;
    await _prefs.setString(_keyTheme, themeName);
  }

  /// 设置主题模式
  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await _prefs.setString(_keyThemeMode, _getThemeModeString(mode));
  }

  /// 设置字体
  static Future<void> setFontFamily(String fontFamily) async {
    AppConfigService.fontFamily = FontFamily.fromValue(fontFamily);
    await _prefs.setString(_keyFontFamily, fontFamily);
  }

  /// 设置语言
  static Future<void> setLocale(String value) async {
    locale = value;
    await _prefs.setString(_keyLocale, value);
  }
}
