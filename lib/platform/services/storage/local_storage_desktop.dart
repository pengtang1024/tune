import 'package:tune/core/storage/storage.dart';

/// 桌面端存储（SQLite）
class LocalStorageDesktop implements Storage {
  @override
  Future<void> set(String key, dynamic value) async {
    // 使用SQLite存储数据
    // TODO: 实现SQLite存储逻辑
  }

  @override
  Future<dynamic> get(String key) async {
    // 使用SQLite读取数据
    // TODO: 实现SQLite读取逻辑
    return null;
  }

  @override
  Future<void> delete(String key) async {
    // 使用SQLite删除数据
    // TODO: 实现SQLite删除逻辑
  }

  @override
  Future<void> clear() async {
    // 使用SQLite清空数据
    // TODO: 实现SQLite清空逻辑
  }
}