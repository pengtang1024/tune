import 'package:tune/data/models/dto/song_dto.dart';
import 'package:tune/domain/entities/song.dart';

/// 歌曲映射器
class SongMapper {
  /// DTO转实体
  static Song toEntity(SongDto dto) {
    return Song(
      id: dto.id,
      title: dto.title,
      artist: dto.artist,
      album: dto.album,
      genre: dto.genre,
      duration: dto.duration,
      uri: dto.uri,
      albumArtUri: dto.albumArtUri,
      dateAdded: dto.dateAdded,
      isFavorite: dto.isFavorite,
    );
  }

  /// 实体转DTO
  static SongDto fromEntity(Song entity) {
    return SongDto(
      id: entity.id,
      title: entity.title,
      artist: entity.artist,
      album: entity.album,
      genre: entity.genre,
      duration: entity.duration,
      uri: entity.uri,
      albumArtUri: entity.albumArtUri,
      dateAdded: entity.dateAdded,
      isFavorite: entity.isFavorite,
    );
  }
}
