import 'package:shared_preferences/shared_preferences.dart';

/// 应用程序配置管理类
/// 
/// 负责管理应用程序的各种配置信息，使用SharedPreferences进行本地持久化存储。
/// 包括主题设置、用户会话信息等。
class AppConfig {
  /// SharedPreferences实例，用于本地数据存储
  static late SharedPreferences _prefs;

  /// 主题模式配置键名
  static const String _keyThemeMode = 'theme_mode';
  
  /// 主题名称配置键名
  static const String _keyThemeName = 'theme_name';
  
  /// 语言配置键名
  static const String _keyLocale = 'locale';
  
  /// 用户ID配置键名
  static const String _keyUserId = 'user_id';
  
  /// 用户令牌配置键名
  static const String _keyUserToken = 'user_token';

  /// 初始化配置管理器
  /// 
  /// 获取SharedPreferences实例，必须在应用程序启动时调用。
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 主题偏好设置
  
  /// 获取当前主题模式
  /// 
  /// 从本地存储中读取主题模式设置，如果未设置则返回默认值'system'。
  /// 
  /// 返回值:
  /// - 'light': 浅色模式
  /// - 'dark': 深色模式
  /// - 'system': 跟随系统设置
  static String get theme {
    return _prefs.getString(_keyThemeName) ?? 'trendyElectro';
  }

  /// 设置主题模式
  /// 
  /// 将主题模式设置保存到本地存储中。
  /// 
  /// [themeMode] 要保存的主题模式字符串
  static Future<void> setTheme(String themeName) async {
    await _prefs.setString(_keyThemeName, themeName);
  }
  
  /// 获取当前语言
  static String get locale {
    return _prefs.getString(_keyLocale) ?? 'en';
  }
  
  /// 设置语言
  static Future<void> setLocale(String locale) async {
    await _prefs.setString(_keyLocale, locale);
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
  }
}