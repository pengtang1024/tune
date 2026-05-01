import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tune/utils/logger.dart';

/// 安全存储服务
/// 用于加密存储敏感数据，如用户令牌、密码等
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  late final FlutterSecureStorage _storage;

  factory SecureStorageService() {
    return _instance;
  }

  SecureStorageService._internal() {
    _storage = const FlutterSecureStorage();
  }

  /// 读取字符串值
  Future<String?> getString(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      Log.error('读取安全存储失败: $e');
      return null;
    }
  }

  /// 保存字符串值
  Future<void> setString(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      Log.error('写入安全存储失败: $e');
    }
  }

  /// 删除指定键的值
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      Log.error('删除安全存储失败: $e');
    }
  }

  /// 清空所有安全存储
  Future<void> clear() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      Log.error('清空安全存储失败: $e');
    }
  }

  /// 检查键是否存在
  Future<bool> containsKey(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      Log.error('检查安全存储键失败: $e');
      return false;
    }
  }
}