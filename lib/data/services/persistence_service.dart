/// 持久化服务接口
abstract class PersistenceService {
  /// 初始化服务
  Future<void> init();

  /// 保存字符串值
  Future<bool> setString(String key, String value);

  /// 获取字符串值
  String? getString(String key);

  /// 保存整数值
  Future<bool> setInt(String key, int value);

  /// 获取整数值
  int? getInt(String key);

  /// 保存布尔值
  Future<bool> setBool(String key, bool value);

  /// 获取布尔值
  bool? getBool(String key);

  /// 保存双精度浮点值
  Future<bool> setDouble(String key, double value);

  /// 获取双精度浮点值
  double? getDouble(String key);

  /// 保存字符串列表
  Future<bool> setStringList(String key, List<String> value);

  /// 获取字符串列表
  List<String>? getStringList(String key);

  /// 检查是否包含指定键
  bool containsKey(String key);

  /// 删除指定键的值
  Future<bool> remove(String key);

  /// 清空所有数据
  Future<bool> clear();

  /// 获取所有键
  Set<String> getKeys();
}