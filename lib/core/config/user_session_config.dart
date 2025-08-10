import 'package:shared_preferences/shared_preferences.dart';

/// 用户会话配置管理类
/// 
/// 负责管理用户会话相关的配置信息，使用SharedPreferences进行本地持久化存储。
class UserSessionConfig {
  /// SharedPreferences实例，用于本地数据存储
  static late SharedPreferences _prefs;

  /// 用户ID配置键名
  static const String _keyUserId = 'user_id';
  
  /// 用户令牌配置键名
  static const String _keyUserToken = 'user_token';

  /// 初始化用户会话配置管理器
  /// 
  /// 获取SharedPreferences实例，必须在应用程序启动时调用。
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

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

  /// 清除所有用户会话配置
  /// 
  /// 清除所有本地存储的用户会话信息，用于用户登出。
  static Future<void> clearAll() async {
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUserToken);
  }
}