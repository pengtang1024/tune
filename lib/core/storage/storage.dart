/// 存储抽象接口
abstract class Storage {
  /// 保存数据
  Future<void> set(String key, dynamic value);

  /// 获取数据
  Future<dynamic> get(String key);

  /// 删除数据
  Future<void> delete(String key);

  /// 清空所有数据
  Future<void> clear();
}

/// 本地存储接口扩展
extension LocalStorageExtension on Storage {
  /// 保存字符串
  Future<void> setString(String key, String value) async {
    await set(key, value);
  }

  /// 获取字符串
  Future<String> getString(String key, {String defaultValue = ''}) async {
    final value = await get(key);
    if (value is String) {
      return value;
    }
    return defaultValue;
  }
}