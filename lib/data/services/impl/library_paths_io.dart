import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/music_scanner_config.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/file_name.dart';

/// The library paths of a build that has a file system.
LibraryPaths createLibraryPaths(PersistenceService persistence) =>
    FileLibraryPaths(persistence);

/// Keeps the files of the app in the music library of the machine.
///
/// A track the user already has keeps the folder it is in: the cover and the
/// lyrics are written next to it, under the name of the file. A track the app
/// fetches gets a folder of its own, named after the artist, the album and
/// the title, so the music library stays a library and no folder holds more
/// than a handful of tracks.
class FileLibraryPaths implements LibraryPaths {
  FileLibraryPaths(this._persistence);

  /// The folder of the app inside the music library.
  ///
  /// It holds the covers of the tracks that were not fetched. The name starts
  /// with a dot, so a music scanner walks past it.
  static const String cacheFolderName = '.tune';

  /// The folder inside the app folder that holds the covers.
  static const String artworkFolderName = 'artwork';

  /// The number of files one folder of the cover cache holds.
  ///
  /// The covers are spread over subfolders, so a single folder never holds
  /// more than a handful of pictures.
  static const int coversPerFolder = 256;

  final PersistenceService _persistence;

  @override
  Directory root() {
    final picked = _persistence.getString(LibraryPaths.rootKey);
    if (picked != null && picked.trim().isNotEmpty) {
      return Directory(picked.trim());
    }
    return defaultRoot();
  }

  /// The music library of the machine.
  static Directory defaultRoot() {
    final folder = MusicScannerConfig.getDefaultMusicLibrary();
    if (folder == null) {
      throw StateError('the platform has no music folder');
    }
    return Directory(folder);
  }

  @override
  Future<Directory> folderFor(Song song) async {
    final local = _localFolderOf(song);
    if (local != null) return local;

    final root = this.root();
    final segments = [
      song.artist,
      song.album,
      song.title,
    ].where((part) => part.trim().isNotEmpty).map(safeFileName);
    return Directory(path.joinAll([root.path, ...segments]));
  }

  @override
  String nameFor(Song song) {
    final local = _localFileOf(song);
    if (local != null) return path.basenameWithoutExtension(local.path);
    return safeFileName(song.title);
  }

  @override
  Future<File> coverFileFor(Song song, String extension) async {
    final folder = await folderFor(song);
    final suffix = extension.startsWith('.') ? extension : '.$extension';
    return File(path.join(folder.path, '${nameFor(song)}$suffix'));
  }

  @override
  Future<File> lyricsFileFor(Song song) => _lyricsFile(song, manual: false);

  /// The file the lyrics of [song] are written to.
  ///
  /// The lyrics the reader brought have a name of their own, so the file the
  /// app matched is never overwritten; the smart sheet carries its own mark.
  Future<File> _lyricsFile(
    Song song, {
    required bool manual,
    bool smart = false,
  }) async {
    final folder = await folderFor(song);
    final name = nameFor(song);
    final suffix = smart ? '.smart' : (manual ? '.manual' : '');
    return File(path.join(folder.path, '$name$suffix.lrc'));
  }

  @override
  Directory coverCacheFolder() {
    return Directory(
      path.join(root().path, cacheFolderName, artworkFolderName),
    );
  }

  @override
  Future<String?> readLyrics(Song song) async {
    final chosen = await _readLyricsFile(_lyricsFile(song, manual: true));
    if (chosen != null) return chosen;
    return _readLyricsFile(_lyricsFile(song, manual: false));
  }

  @override
  Future<void> saveLyrics(Song song, String lyrics) async {
    final file = await lyricsFileFor(song);
    await file.parent.create(recursive: true);
    await file.writeAsString(lyrics, flush: true);
  }

  @override
  Future<void> saveChosenLyrics(Song song, String lyrics) async {
    final matched = await lyricsFileFor(song);
    final target = await matched.exists()
        ? await _lyricsFile(song, manual: true)
        : matched;
    await target.parent.create(recursive: true);
    await target.writeAsString(lyrics, flush: true);
  }

  /// Reads a lyrics file, when it is there and can be read.
  Future<String?> _readLyricsFile(Future<File> file) async {
    try {
      final target = await file;
      if (!await target.exists()) return null;
      return await target.readAsString();
    } catch (error) {
      return null;
    }
  }

  @override
  Future<void> saveSmartLyrics(Song song, String lyrics) async {
    final file = await _lyricsFile(song, manual: false, smart: true);
    await file.parent.create(recursive: true);
    await file.writeAsString(lyrics, flush: true);
  }

  @override
  Future<String?> readSmartLyrics(Song song) {
    return _readLyricsFile(_lyricsFile(song, manual: false, smart: true));
  }

  @override
  Future<void> saveSmartContrast(Song song, String json) async {
    final file = await _contrastFile(song);
    await file.parent.create(recursive: true);
    await file.writeAsString(json, flush: true);
  }

  @override
  Future<String?> readSmartContrast(Song song) {
    return _readLyricsFile(_contrastFile(song));
  }

  @override
  Future<void> clearSmartContrast(Song song) async {
    final file = await _contrastFile(song);
    if (await file.exists()) await file.delete();
  }

  /// The contrasts of [song]: a small json beside the sheet they belong
  /// to, so the family of the song's files stays in one folder.
  Future<File> _contrastFile(Song song) async {
    final folder = await folderFor(song);
    final name = nameFor(song);
    return File(path.join(folder.path, '$name.smart.json'));
  }

  /// The file of a track that is on the disk, when the track is one.
  ///
  /// A remote track keeps a canonical `tune://` URI for its identity, and
  /// that URI names the track instead of pointing at a file. Only a track
  /// that really has a file of its own keeps the place it is in.
  File? _localFileOf(Song song) {
    if (!song.isLocalFile) return null;
    final parsed = Uri.tryParse(song.uri);
    if (parsed != null && parsed.scheme == 'file') {
      return File(parsed.toFilePath());
    }
    return File(song.uri);
  }


  /// The folder of a track that is on the disk, when the track is one.
  Directory? _localFolderOf(Song song) {
    final file = _localFileOf(song);
    if (file == null) return null;
    return file.parent;
  }
}
