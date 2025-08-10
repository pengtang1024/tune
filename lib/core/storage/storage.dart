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