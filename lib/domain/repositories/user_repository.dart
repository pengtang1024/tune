import 'package:tune/domain/entities/user.dart';

/// 用户仓库接口
abstract class UserRepository {
  /// 用户登录
  Future<User> login(String username, String password);

  /// 用户注册
  Future<User> register(String username, String email, String password);

  /// 获取当前用户
  Future<User?> getCurrentUser();

  /// 更新用户信息
  Future<User> updateUserInfo(User user);

  /// 用户登出
  Future<void> logout();
}