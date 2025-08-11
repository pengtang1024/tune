import 'package:shared_preferences/shared_preferences.dart';
import 'package:tune/core/storage/storage.dart';

/// 本地存储实现类
///
/// 基于SharedPreferences实现的本地存储，用于存储应用配置和用户数据。
class LocalStorageImpl implements Storage {
  late SharedPreferences _prefs;

  /// 初始化本地存储
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<void> set(String key, dynamic value) async {
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    }
  }

  @override
  Future<dynamic> get(String key) async {
    return _prefs.get(key);
  }

  @override
  Future<void> delete(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}