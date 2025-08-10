/// 用户DTO
class UserDto {
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
  UserDto({
    required this.id,
    required this.username,
    this.email,
    this.avatarUri,
    required this.createdAt,
    required this.isVip,
  });

  /// 从JSON创建DTO
  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      avatarUri: json['avatarUri'] as String?,
      createdAt: json['createdAt'] as int,
      isVip: json['isVip'] as bool,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatarUri': avatarUri,
      'createdAt': createdAt,
      'isVip': isVip,
    };
  }
}