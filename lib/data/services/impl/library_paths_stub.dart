import 'dart:io';

import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/domain/models/song.dart';

/// The library paths of a build that has no file system.
LibraryPaths createLibraryPaths(PersistenceService persistence) =>
    BrowserLibraryPaths(persistence);

/// Keeps the files of the app in the browser, for the build without a file
/// system.
///
/// The web build has no music library to write into, so there is no place for
/// a fetched track, a cover or a lyric sheet. The app keeps what it fetched
/// in memory and fetches it again after a reload.
class BrowserLibraryPaths implements LibraryPaths {
  BrowserLibraryPaths(PersistenceService persistence);

  @override
  Future<Directory> root() async {
    throw UnsupportedError('the web build has no music library');
  }

  @override
  Future<Directory> folderFor(Song song) async {
    throw UnsupportedError('the web build has no music library');
  }

  @override
  String nameFor(Song song) => song.title;

  @override
  Future<File> coverFileFor(Song song, String extension) async {
    throw UnsupportedError('the web build has no music library');
  }

  @override
  Future<File> lyricsFileFor(Song song) async {
    throw UnsupportedError('the web build has no music library');
  }

  @override
  Future<Directory> coverCacheFolder() async {
    throw UnsupportedError('the web build has no music library');
  }

  @override
  Future<String?> readLyrics(Song song) async => null;

  @override
  Future<void> saveLyrics(Song song, String lyrics) async {}
}
