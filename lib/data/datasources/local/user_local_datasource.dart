import 'package:tune/domain/entities/user.dart';

/// 用户本地数据源
abstract class UserLocalDataSource {
  /// 保存用户信息
  Future<void> saveUser(User user);

  /// 获取当前用户
  Future<User?> getCurrentUser();

  /// 清除用户信息
  Future<void> clearUser();
}