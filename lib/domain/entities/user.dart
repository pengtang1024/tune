import 'package:equatable/equatable.dart';

/// 用户实体
class User extends Equatable {
  /// 用户ID
  final String id;

  /// 用户名
  final String username;

  /// 邮箱
  final String? email;

  /// 头像URI
  final String? avatarUri;

  /// 创建时间
  final int createdAt;

  /// 是否为VIP用户
  final bool isVip;

  /// 构造函数
  const User({
    required this.id,
    required this.username,
    this.email,
    this.avatarUri,
    required this.createdAt,
    this.isVip = false,
  });

  /// 创建一个包含默认值的新用户实例
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUri,
    int? createdAt,
    bool? isVip,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUri: avatarUri ?? this.avatarUri,
      createdAt: createdAt ?? this.createdAt,
      isVip: isVip ?? this.isVip,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        avatarUri,
        createdAt,
        isVip,
      ];
}