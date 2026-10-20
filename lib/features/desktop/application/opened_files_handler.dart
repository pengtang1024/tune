import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/utils/logger.dart';

/// Opens the files the player was asked to play.
///
/// The files come from the desktop: the command line of a start, or another
/// start that handed them over. They are read, put into the library and
/// played.
class OpenedFilesHandler {
  OpenedFilesHandler({
    required this.scanner,
    required this.playback,
    required this.addToLibrary,
  });

  final CrossPlatformMusicScanner scanner;
  final PlaybackController playback;

  /// Puts the songs into the library of the player.
  final Future<void> Function(List<Song> songs) addToLibrary;

  /// Reads the files and starts playing them.
  Future<void> open(List<String> paths) async {
    if (paths.isEmpty) return;

    final songs = <Song>[];
    for (final path in paths) {
      final song = await _readSong(path);
      if (song != null) songs.add(song);
    }
    if (songs.isEmpty) return;

    await addToLibrary(songs);
    await playback.playQueue(songs);
  }

  /// Reads one file into a song.
  ///
  /// A file that cannot be read is skipped: the other files of the request
  /// are still worth playing.
  Future<Song?> _readSong(String path) async {
    try {
      return await scanner.scanMusicFile(path);
    } catch (error, stackTrace) {
      Log.error('读取文件失败: $path\n$stackTrace');
      return null;
    }
  }
}
