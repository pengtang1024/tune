import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart' as audio_meta;

/// 歌曲创建工具类
class SongCreator {
  /// 从文件创建歌曲对象
  static Future<Song?> createFromFile(File file) async {
    final filePath = file.path;
    final fileName = path.basenameWithoutExtension(filePath);

    try {
      final metadata = audio_meta.readMetadata(file);

      final songData = <String, dynamic>{
        'id': filePath.hashCode,
        'title': metadata.title ?? fileName,
        'artist': metadata.artist ?? 'Unknown Artist',
        'album': metadata.album ?? 'Unknown Album',
        'duration': metadata.duration?.inMilliseconds ?? 0,
        'data': filePath,
        'uri': filePath,
        'dateAdded': DateTime.now().millisecondsSinceEpoch,
        'year': metadata.year?.year,
        'genre': metadata.genres.isNotEmpty == true
            ? metadata.genres.first
            : null,
        'bitrate': metadata.bitrate,
        'sampleRate': metadata.sampleRate,
        'trackNumber': metadata.trackNumber,
        'trackTotal': metadata.trackTotal,
        'discNumber': metadata.discNumber,
        'totalDisc': metadata.totalDisc,
        'lyrics': metadata.lyrics,
        'genres': metadata.genres,
        'performers': metadata.performers,
        'language': metadata.language,
        'size': await file.length(),
        'type': 'audio',
        'isFavorite': false,
      };

      return Song.fromMap(songData);
    } catch (e) {
      Log.info('SongCreator: Failed to read metadata for $filePath: $e');
      return await createBasicSong(file, fileName, filePath);
    }
  }

  static Future<Song> createBasicSong(
    File file,
    String fileName,
    String filePath,
  ) async {
    final songData = <String, dynamic>{
      'id': filePath.hashCode,
      'title': fileName,
      'artist': 'Unknown Artist',
      'album': 'Unknown Album',
      'duration': 0,
      'uri': filePath,
      'dateAdded': DateTime.now().millisecondsSinceEpoch,
      'year': 0,
      'size': await file.length(),
      'type': 'audio',
      'isFavorite': false,
    };

    return Song.fromMap(songData);
  }
}
