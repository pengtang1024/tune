import 'package:tune/core/storage/storage.dart';

/// Web端存储（localStorage）
class LocalStorageWeb implements Storage {
  @override
  Future<void> set(String key, dynamic value) async {
    // 使用localStorage存储数据
    // TODO: 实现localStorage存储逻辑
  }

  @override
  Future<dynamic> get(String key) async {
    // 使用localStorage读取数据
    // TODO: 实现localStorage读取逻辑
    return null;
  }

  @override
  Future<void> delete(String key) async {
    // 使用localStorage删除数据
    // TODO: 实现localStorage删除逻辑
  }

  @override
  Future<void> clear() async {
    // 使用localStorage清空数据
    // TODO: 实现localStorage清空逻辑
  }
}