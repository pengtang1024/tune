import 'package:equatable/equatable.dart';
import 'package:tune/domain/entities/song.dart';

/// 播放列表实体
class Playlist extends Equatable {
  /// 播放列表ID
  final int id;

  /// 播放列表名称
  final String name;

  /// 播放列表描述
  final String? description;

  /// 播放列表封面URI
  final String? coverUri;

  /// 包含的歌曲列表
  final List<Song> songs;

  /// 创建时间
  final int createdAt;

  /// 更新时间
  final int updatedAt;

  /// 构造函数
  const Playlist({
    required this.id,
    required this.name,
    this.description,
    this.coverUri,
    required this.songs,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 创建一个包含默认值的新播放列表实例
  Playlist copyWith({
    int? id,
    String? name,
    String? description,
    String? coverUri,
    List<Song>? songs,
    int? createdAt,
    int? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUri: coverUri ?? this.coverUri,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        coverUri,
        songs,
        createdAt,
        updatedAt,
      ];
}