import 'package:on_audio_query/on_audio_query.dart' as on_audio;
import 'package:tune/domain/entities/song.dart';

class SongModel extends Song {
  const SongModel({
    required super.id,
    required super.title,
    required super.artist,
    required super.album,
    required super.genre,
    required super.duration,
    required super.uri,
    super.albumArtUri,
    required super.dateAdded,
    super.isFavorite = false,
  });

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'] as int,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String,
      genre: map['genre'] as String,
      duration: map['duration'] as int,
      uri: map['uri'] as String,
      albumArtUri: map['albumArtUri'] as String?,
      dateAdded: map['dateAdded'] as int,
      isFavorite: map['isFavorite'] as bool? ?? false,
    );
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    // 复用fromMap方法以避免重复代码
    return SongModel.fromMap(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'duration': duration,
      'uri': uri,
      'albumArtUri': albumArtUri,
      'dateAdded': dateAdded,
      'isFavorite': isFavorite,
    };
  }

  Song toEntity() {
    return Song(
      id: id,
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      duration: duration,
      uri: uri,
      albumArtUri: albumArtUri,
      dateAdded: dateAdded,
      isFavorite: isFavorite,
    );
  }

  /// 从on_audio_query的SongModel创建SongModel
  factory SongModel.fromAudioQuerySong(on_audio.SongModel song) {
    return SongModel(
      id: song.id,
      title: song.title,
      artist: song.artist ?? 'Unknown Artist',
      album: song.album ?? 'Unknown Album',
      genre: song.genre ?? 'Unknown Genre',
      duration: song.duration ?? 0,
      uri: song.uri ?? '',
      albumArtUri: null,
      dateAdded: 0,
      isFavorite: false,
    );
  }
}
