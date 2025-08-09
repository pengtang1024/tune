import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用程序配置管理类
/// 
/// 负责管理应用程序的各种配置信息，使用SharedPreferences进行本地持久化存储。
/// 包括主题设置、用户会话信息等。
class AppConfig {
  /// SharedPreferences实例，用于本地数据存储
  static late SharedPreferences _prefs;

  /// 主题名称配置键名
  static const String _keyTheme = 'theme';
  
  /// 主题模式配置键名
  static const String _keyThemeMode = 'theme_mode';
  
  /// 语言配置键名
  static const String _keyLocale = 'locale';
  
  /// 用户ID配置键名
  static const String _keyUserId = 'user_id';
  
  /// 用户令牌配置键名
  static const String _keyUserToken = 'user_token';
  
  /// 当前语言
  static String locale = 'en';
  
  /// 当前主题
  static String theme = 'trendyElectro';
  
  /// 当前主题模式
  static ThemeMode themeMode = ThemeMode.system;

  /// 初始化配置管理器
  /// 
  /// 获取SharedPreferences实例，必须在应用程序启动时调用。
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    locale = _prefs.getString(_keyLocale) ?? 'en';
    theme = _getValidThemeName(_prefs.getString(_keyTheme));
    themeMode = _getThemeModeFromString(_prefs.getString(_keyThemeMode));
  }

  /// 获取有效的主题名称
  /// 
  /// 验证并返回有效的主题名称，如果存储的主题名称无效则返回默认主题
  static String _getValidThemeName(String? storedTheme) {
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
      default:
        return 'system';
    }
  }

  // 主题偏好设置
  
  /// 设置语言
  static Future<void> setLocale(String value) async {
    locale = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, value);
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

  // 用户会话管理
  
  /// 获取用户ID
  /// 
  /// 从本地存储中读取用户ID，如果用户未登录则返回null。
  static String? getUserId() {
    return _prefs.getString(_keyUserId);
  }

  /// 设置用户ID
  /// 
  /// 将用户ID保存到本地存储中。
  /// 
  /// [userId] 要保存的用户ID
  static Future<void> setUserId(String userId) async {
    await _prefs.setString(_keyUserId, userId);
  }

  /// 清除用户ID
  /// 
  /// 从本地存储中移除用户ID，用于用户登出操作。
  static Future<void> clearUserId() async {
    await _prefs.remove(_keyUserId);
  }

  /// 获取用户令牌
  /// 
  /// 从本地存储中读取用户令牌，如果用户未登录则返回null。
  static String? getUserToken() {
    return _prefs.getString(_keyUserToken);
  }

  /// 设置用户令牌
  /// 
  /// 将用户令牌保存到本地存储中。
  /// 
  /// [token] 要保存的用户令牌
  static Future<void> setUserToken(String token) async {
    await _prefs.setString(_keyUserToken, token);
  }

  /// 清除用户令牌
  /// 
  /// 从本地存储中移除用户令牌，用于用户登出操作。
  static Future<void> clearUserToken() async {
    await _prefs.remove(_keyUserToken);
  }

  /// 清除所有配置
  /// 
  /// 清除所有本地存储的配置信息，用于用户登出或重置应用设置。
  static Future<void> clearAll() async {
    await _prefs.clear();
    
    // 重置默认值
    locale = 'en';
    theme = 'trendyElectro';
  }
}