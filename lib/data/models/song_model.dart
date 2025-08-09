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
      isFavorite: map['isFavorite'] as bool,
    );
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] as int,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      genre: json['genre'] as String,
      duration: json['duration'] as int,
      uri: json['uri'] as String,
      albumArtUri: json['albumArtUri'] as String?,
      dateAdded: json['dateAdded'] as int,
      isFavorite: json['isFavorite'] as bool,
    );
  }

  /// 转换为实体对象
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

  Map<String, dynamic> toMap() {
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

  @override
  SongModel copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    String? genre,
    int? duration,
    String? uri,
    String? albumArtUri,
    int? dateAdded,
    bool? isFavorite,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      duration: duration ?? this.duration,
      uri: uri ?? this.uri,
      albumArtUri: albumArtUri ?? this.albumArtUri,
      dateAdded: dateAdded ?? this.dateAdded,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
