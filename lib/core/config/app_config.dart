import 'package:flutter/material.dart';
import 'package:tune/core/config/localization_config.dart';
import 'package:tune/core/config/theme_config.dart';
import 'package:tune/core/config/user_session_config.dart';

/// 应用程序配置管理类
/// 
/// 负责统一管理应用程序的所有配置信息。
/// 将不同类型的配置分散到专门的配置类中，提高代码的模块化和可维护性。
class AppConfig {
  /// 初始化所有配置管理器
  /// 
  /// 必须在应用程序启动时调用，用于初始化所有配置管理器。
  static Future<void> init() async {
    await Future.wait([
      LocalizationConfig.init(),
      ThemeConfig.init(),
      UserSessionConfig.init(),
    ]);
  }

  // 本地化配置相关静态getter和setter方法
  
  /// 获取当前语言
  static String get locale => LocalizationConfig.locale;
  
  /// 设置语言
  static Future<void> setLocale(String value) => LocalizationConfig.setLocale(value);

  // 主题配置相关静态getter和setter方法
  
  /// 获取当前主题
  static String get theme => ThemeConfig.theme;
  
  /// 设置主题
  static Future<void> setTheme(String value) => ThemeConfig.setTheme(value);
  
  /// 获取当前主题模式
  static ThemeMode get themeMode => ThemeConfig.themeMode;
  
  /// 设置主题模式
  static Future<void> setThemeMode(ThemeMode value) => ThemeConfig.setThemeMode(value);
  
  /// 获取当前字体
  static AppFontFamily get fontFamily => ThemeConfig.fontFamily;
  
  /// 设置字体
  static Future<void> setFontFamily(AppFontFamily value) => ThemeConfig.setFontFamily(value);
  
  /// 获取有效的主题名称
  static String getValidThemeName(String? storedTheme) => ThemeConfig.getValidThemeName(storedTheme);

  // 用户会话配置相关静态getter和setter方法
  
  /// 获取用户ID
  static String? getUserId() => UserSessionConfig.getUserId();
  
  /// 设置用户ID
  static Future<void> setUserId(String userId) => UserSessionConfig.setUserId(userId);
  
  /// 清除用户ID
  static Future<void> clearUserId() => UserSessionConfig.clearUserId();
  
  /// 获取用户令牌
  static String? getUserToken() => UserSessionConfig.getUserToken();
  
  /// 设置用户令牌
  static Future<void> setUserToken(String token) => UserSessionConfig.setUserToken(token);
  
  /// 清除用户令牌
  static Future<void> clearUserToken() => UserSessionConfig.clearUserToken();
  
  /// 清除所有用户会话配置
  static Future<void> clearUserSession() => UserSessionConfig.clearAll();
  
  /// 清除所有配置
  /// 
  /// 清除所有本地存储的配置信息，用于用户登出或重置应用设置。
  static Future<void> clearAll() async {
    await Future.wait([
      UserSessionConfig.clearAll(),
    ]);
    
    // 重置为默认配置
    LocalizationConfig.locale = 'en';
    ThemeConfig.theme = 'trendyElectro';
    ThemeConfig.fontFamily = AppFontFamily.defaultFont;
  }
}