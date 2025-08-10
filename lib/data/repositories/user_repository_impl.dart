import 'package:tune/data/datasources/local/user_local_datasource.dart';
import 'package:tune/data/datasources/remote/user_remote_datasource.dart';
import 'package:tune/domain/entities/user.dart';
import 'package:tune/domain/repositories/user_repository.dart';

/// 用户仓库实现
class UserRepositoryImpl implements UserRepository {
  /// 本地数据源
  final UserLocalDataSource localDataSource;

  /// 远程数据源
  final UserRemoteDataSource remoteDataSource;

  /// 构造函数
  UserRepositoryImpl(this.localDataSource, this.remoteDataSource);

  @override
  Future<User> login(String username, String password) async {
    // 调用远程数据源进行登录
    final user = await remoteDataSource.login(username, password);

    // 保存用户信息到本地
    await localDataSource.saveUser(user);

    return user;
  }

  @override
  Future<User> register(String username, String email, String password) async {
    // 调用远程数据源进行注册
    final user = await remoteDataSource.register(username, email, password);

    // 保存用户信息到本地
    await localDataSource.saveUser(user);

    return user;
  }

  @override
  Future<User?> getCurrentUser() async {
    // 首先尝试从本地获取用户信息
    final localUser = await localDataSource.getCurrentUser();
    if (localUser != null) {
      return localUser;
    }

    // 如果本地没有，则从远程获取
    try {
      final remoteUser = await remoteDataSource.getCurrentUser();
      if (remoteUser != null) {
        // 保存到本地
        await localDataSource.saveUser(remoteUser);
        return remoteUser;
      }
    } catch (e) {
      // 忽略远程获取错误
    }

    return null;
  }

  @override
  Future<User> updateUserInfo(User user) async {
    // 更新远程用户信息
    final updatedUser = await remoteDataSource.updateUserInfo(user);

    // 更新本地用户信息
    await localDataSource.saveUser(updatedUser);

    return updatedUser;
  }

  @override
  Future<void> logout() async {
    // 清除本地用户信息
    await localDataSource.clearUser();

    // 调用远程登出
    await remoteDataSource.logout();
  }
}