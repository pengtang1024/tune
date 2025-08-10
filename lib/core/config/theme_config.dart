import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用程序支持的字体枚举
enum AppFontFamily {
  defaultFont('JetBrainsMono-Light'),
  roboto('Roboto'),
  poppins('Poppins'),
  lato('Lato'),
  openSans('Open Sans'),
  jetbrainsMonoRegular('JetBrainsMono-Regular'),
  jetbrainsMonoBold('JetBrainsMono-Bold'),
  jetbrainsMonoLight('JetBrainsMono-Light'),
  jetbrainsMonoMedium('JetBrainsMono-Medium'),
  jetbrainsMonoSemiBold('JetBrainsMono-SemiBold'),
  jetbrainsMonoExtraBold('JetBrainsMono-ExtraBold'),
  jetbrainsMonoExtraLight('JetBrainsMono-ExtraLight'),
  jetbrainsMonoThin('JetBrainsMono-Thin'),
  jetbrainsMonoNlRegular('JetBrainsMonoNL-Regular'),
  jetbrainsMonoNlBold('JetBrainsMonoNL-Bold'),
  jetbrainsMonoNlLight('JetBrainsMonoNL-Light'),
  jetbrainsMonoNlMedium('JetBrainsMonoNL-Medium'),
  jetbrainsMonoNlSemiBold('JetBrainsMonoNL-SemiBold'),
  jetbrainsMonoNlExtraBold('JetBrainsMonoNL-ExtraBold'),
  jetbrainsMonoNlExtraLight('JetBrainsMonoNL-ExtraLight'),
  jetbrainsMonoNlThin('JetBrainsMonoNL-Thin');

  const AppFontFamily(this.value);
  final String value;

  static AppFontFamily fromValue(String? value) {
    // 检查是否为JetBrains字体系列
    if (value != null && value.startsWith('JetBrainsMono')) {
      // 直接根据值查找对应的枚举
      try {
        return values.firstWhere((font) => font.value == value);
      } catch (e) {
        // 如果找不到匹配的值，返回默认字体
        return defaultFont;
      }
    }
    
    // 对于其他值，使用原来的查找逻辑
    return values.firstWhere(
      (font) => font.value == value,
      orElse: () => defaultFont,
    );
  }
}

/// 应用主题配置管理类
/// 
/// 负责管理应用程序的主题相关配置信息，使用SharedPreferences进行本地持久化存储。
class ThemeConfig {
  /// SharedPreferences实例，用于本地数据存储
  static late SharedPreferences _prefs;

  /// 主题名称配置键名
  static const String _keyTheme = 'theme';
  
  /// 主题模式配置键名
  static const String _keyThemeMode = 'theme_mode';
  
  /// 字体配置键名
  static const String _keyFontFamily = 'font_family';

  /// 当前主题
  static String theme = 'trendyElectro';
  
  /// 当前主题模式
  static ThemeMode themeMode = ThemeMode.system;
  
  /// 当前字体
  static AppFontFamily fontFamily = AppFontFamily.defaultFont;

  /// 初始化主题配置管理器
  /// 
  /// 获取SharedPreferences实例，必须在应用程序启动时调用。
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    theme = getValidThemeName(_prefs.getString(_keyTheme));
    themeMode = _getThemeModeFromString(_prefs.getString(_keyThemeMode));
    final storedFont = _prefs.getString(_keyFontFamily);
    fontFamily = AppFontFamily.fromValue(storedFont);
  }

  /// 获取有效的主题名称
  /// 
  /// 验证并返回有效的主题名称，如果存储的主题名称无效则返回默认主题
  static String getValidThemeName(String? storedTheme) {
    // 有效的主题列表
    const validThemes = [
      'trendyElectro',
      'minimalGray', 
      'natureForest',
      'cyberNeon',
      'warmHealing'
    ];
    
    // 如果存储的主题名称有效，直接返回
    if (storedTheme != null && validThemes.contains(storedTheme)) {
      return storedTheme;
    }
    
    // 否则返回默认主题
    return 'trendyElectro';
  }
  
  /// 将字符串转换为ThemeMode
  /// 
  /// 根据存储的字符串值返回对应的ThemeMode枚举值
  static ThemeMode _getThemeModeFromString(String? themeModeString) {
    switch (themeModeString) {
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
  
  /// 将ThemeMode转换为字符串
  /// 
  /// 将ThemeMode枚举值转换为可存储的字符串值
  static String _themeModeToString(ThemeMode themeMode) {
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
  static Future<void> setTheme(String value) async {
    theme = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, value);
  }
  
  /// 设置主题模式
  static Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, _themeModeToString(value));
  }
  
  /// 设置字体
  static Future<void> setFontFamily(AppFontFamily value) async {
    fontFamily = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFontFamily, value.value);
  }
}