import 'package:shared_preferences/shared_preferences.dart';

/// 本地化配置管理类
/// 
/// 负责管理应用程序的本地化相关配置信息，使用SharedPreferences进行本地持久化存储。
class LocalizationConfig {
  /// SharedPreferences实例，用于本地数据存储
  static late SharedPreferences _prefs;

  /// 语言配置键名
  static const String _keyLocale = 'locale';

  /// 当前语言
  static String locale = 'en';

  /// 初始化本地化配置管理器
  /// 
  /// 获取SharedPreferences实例，必须在应用程序启动时调用。
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    locale = _prefs.getString(_keyLocale) ?? 'en';
  }

  /// 设置语言
  static Future<void> setLocale(String value) async {
    locale = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, value);
  }
}