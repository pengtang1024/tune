import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/library/copy_marker.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart' as audio_meta;

/// 歌曲创建工具类
class SongCreator {
  /// Whether a lyrics sheet sits next to [file].
  ///
  /// The names are the ones the app reads and writes the sheets under
  /// (`LibraryPaths`): the sheet the app matched (`<name>.lrc`), the one
  /// the reader brought (`<name>.manual.lrc`), and the one the smart
  /// pipeline wrote (`<name>.smart.lrc`). One `exists()` per name is
  /// nothing next to the metadata read every scan already pays for.
  static Future<bool> _hasLyricsSheet(File file, String fileName) async {
    final folder = file.parent;
    for (final suffix in const ['.lrc', '.manual.lrc', '.smart.lrc']) {
      if (await File(path.join(folder.path, '$fileName$suffix')).exists()) {
        return true;
      }
    }
    return false;
  }

  /// 从文件创建歌曲对象
  static Future<Song?> createFromFile(File file) async {
    final filePath = file.path;
    final fileName = path.basenameWithoutExtension(filePath);

    // A file the app fetched carries a marker: it is the copy of a track
    // that also comes from a source, not a track of its own.
    final copyUri = await CopyMarker.readUri(file);

    try {
      final metadata = audio_meta.readMetadata(file);

      final songData = <String, dynamic>{
        'id': filePath.hashCode,
        'title': metadata.title ?? fileName,
        'artist': metadata.artist ?? '',
        'album': metadata.album ?? '',
        'duration': metadata.duration?.inMilliseconds ?? 0,
        'data': filePath,
        'uri': copyUri ?? filePath,
        'localPath': copyUri == null ? null : filePath,
        'sourceId': copyUri == null ? null : SourceSongFactory.sourceIdOf(copyUri),
        'externalId': copyUri == null
            ? null
            : SourceSongFactory.externalIdOf(copyUri),
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
        'hasLyrics': (metadata.lyrics?.trim().isNotEmpty ?? false) ||
            await _hasLyricsSheet(file, fileName),
        'genres': metadata.genres,
        'performers': metadata.performers,
        'language': metadata.language,
        'size': await file.length(),
        'type': 'audio',
      };

      return Song.fromMap(songData);
    } catch (e) {
      Log.info('SongCreator: Failed to read metadata for $filePath: $e');
      return await createBasicSong(file, fileName, filePath, copyUri: copyUri);
    }
  }

  static Future<Song> createBasicSong(
    File file,
    String fileName,
    String filePath, {
    String? copyUri,
  }) async {
    final songData = <String, dynamic>{
      'id': filePath.hashCode,
      'title': fileName,
      'artist': '',
      'album': '',
      'duration': 0,
      'uri': copyUri ?? filePath,
      'localPath': copyUri == null ? null : filePath,
      'sourceId': copyUri == null ? null : SourceSongFactory.sourceIdOf(copyUri),
      'externalId': copyUri == null
          ? null
          : SourceSongFactory.externalIdOf(copyUri),
      'dateAdded': DateTime.now().millisecondsSinceEpoch,
      'year': 0,
      'size': await file.length(),
      'type': 'audio',
      'hasLyrics': await _hasLyricsSheet(file, fileName),
    };

    return Song.fromMap(songData);
  }
}
