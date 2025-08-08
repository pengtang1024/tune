import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static late SharedPreferences _prefs;

  static const String _keyThemeMode = 'theme_mode';
  static const String _keyUserId = 'user_id';
  static const String _keyUserToken = 'user_token';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Theme preferences
  static String getThemeMode() {
    return _prefs.getString(_keyThemeMode) ?? 'system';
  }

  static Future<void> setThemeMode(String themeMode) async {
    await _prefs.setString(_keyThemeMode, themeMode);
  }

  // User session
  static String? getUserId() {
    return _prefs.getString(_keyUserId);
  }

  static Future<void> setUserId(String userId) async {
    await _prefs.setString(_keyUserId, userId);
  }

  static Future<void> clearUserId() async {
    await _prefs.remove(_keyUserId);
  }

  static String? getUserToken() {
    return _prefs.getString(_keyUserToken);
  }

  static Future<void> setUserToken(String token) async {
    await _prefs.setString(_keyUserToken, token);
  }

  static Future<void> clearUserToken() async {
    await _prefs.remove(_keyUserToken);
  }

  static Future<void> clearAll() async {
    await _prefs.clear();
  }
}