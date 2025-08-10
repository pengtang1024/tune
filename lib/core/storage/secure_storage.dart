/// 安全存储抽象接口
abstract class SecureStorage {
  /// 保存敏感数据
  Future<void> write(String key, String value);

  /// 读取敏感数据
  Future<String?> read(String key);

  /// 删除敏感数据
  Future<void> delete(String key);

  /// 清空所有敏感数据
  Future<void> clear();
}