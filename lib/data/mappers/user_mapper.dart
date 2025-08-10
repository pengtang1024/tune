import 'package:tune/data/models/dto/user_dto.dart';
import 'package:tune/domain/entities/user.dart';

/// 用户映射器
class UserMapper {
  /// DTO转实体
  static User toEntity(UserDto dto) {
    return User(
      id: dto.id,
      username: dto.username,
      email: dto.email,
      avatarUri: dto.avatarUri,
      createdAt: dto.createdAt,
      isVip: dto.isVip,
    );
  }

  /// 实体转DTO
  static UserDto fromEntity(User entity) {
    return UserDto(
      id: entity.id,
      username: entity.username,
      email: entity.email,
      avatarUri: entity.avatarUri,
      createdAt: entity.createdAt,
      isVip: entity.isVip,
    );
  }
}
