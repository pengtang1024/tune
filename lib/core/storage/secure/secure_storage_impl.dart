import 'package:shared_preferences/shared_preferences.dart';
import 'package:tune/core/storage/secure_storage.dart';

/// 安全存储实现类
///
/// 基于SharedPreferences实现的安全存储，用于存储敏感数据如用户凭证等。
/// 注意：在生产环境中，应该使用加密存储来保护敏感数据。
class SecureStorageImpl implements SecureStorage {
  late SharedPreferences _prefs;

  /// 初始化安全存储
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      // 在实际应用中可以记录日志或进行错误上报
      rethrow;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    // 注意：在实际应用中，应该对敏感数据进行加密后再存储
    try {
      await _prefs.setString('secure_$key', value);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      return _prefs.getString('secure_$key');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _prefs.remove('secure_$key');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    try {
      final keys = _prefs.getKeys();
      final secureKeys = keys.where((key) => key.startsWith('secure_')).toList();
      final futures = secureKeys.map((key) => _prefs.remove(key));
      await Future.wait(futures);
    } catch (e) {
      rethrow;
    }
  }
}