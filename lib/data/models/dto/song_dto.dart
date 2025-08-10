/// 歌曲DTO
class SongDto {
  /// 歌曲ID
  final int id;

  /// 歌曲标题
  final String title;

  /// 歌手
  final String artist;

  /// 专辑
  final String album;

  /// 流派
  final String genre;

  /// 时长（秒）
  final int duration;

  /// 文件URI
  final String uri;

  /// 专辑封面URI
  final String? albumArtUri;

  /// 添加日期
  final int dateAdded;

  /// 是否收藏
  final bool isFavorite;

  /// 构造函数
  SongDto({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.duration,
    required this.uri,
    this.albumArtUri,
    required this.dateAdded,
    required this.isFavorite,
  });

  /// 从JSON创建DTO
  factory SongDto.fromJson(Map<String, dynamic> json) {
    return SongDto(
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

  /// 转换为JSON
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
}