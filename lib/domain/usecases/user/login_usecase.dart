import 'package:tune/domain/entities/user.dart';
import 'package:tune/domain/repositories/user_repository.dart';

/// 登录用例
class LoginUseCase {
  /// 用户仓库
  final UserRepository repository;

  /// 构造函数
  LoginUseCase(this.repository);

  /// 执行用例
  Future<User> call(String username, String password) async {
    return await repository.login(username, password);
  }
}