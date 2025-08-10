import 'package:tune/core/storage/storage.dart';

/// 移动端存储（Hive）
class LocalStorageMobile implements Storage {
  @override
  Future<void> set(String key, dynamic value) async {
    // 使用Hive存储数据
    // TODO: 实现Hive存储逻辑
  }

  @override
  Future<dynamic> get(String key) async {
    // 使用Hive读取数据
    // TODO: 实现Hive读取逻辑
    return null;
  }

  @override
  Future<void> delete(String key) async {
    // 使用Hive删除数据
    // TODO: 实现Hive删除逻辑
  }

  @override
  Future<void> clear() async {
    // 使用Hive清空数据
    // TODO: 实现Hive清空逻辑
  }
}