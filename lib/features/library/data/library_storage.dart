import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';

/// Persists the scanned library as a single JSON document.
///
/// The library is the index the app keeps of the music that is on disk. It
/// belongs to the app, so it lives in the application support folder next to
/// the other data of the app, and not in a folder of the user.
///
/// This file is intentionally outside the controllers: both scanning and
/// startup loading should go through the same storage boundary.
class LibraryStorage {
  LibraryStorage({
    Future<Directory> Function()? supportDirectory,
    Future<Directory> Function()? documentsDirectory,
  }) : _supportDirectory = supportDirectory,
       _documentsDirectory = documentsDirectory;

  static const _fileName = 'scanned_songs.json';
  static const _folderName = 'library';

  /// Where the app keeps its data.
  final Future<Directory> Function()? _supportDirectory;

  /// Where the documents folder of the user is, which holds the library of an
  /// older version.
  final Future<Directory> Function()? _documentsDirectory;

  Future<File> _file() async {
    final base =
        await (_supportDirectory?.call() ?? getApplicationSupportDirectory());
    final directory = Directory(path.join(base.path, _folderName));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File(path.join(directory.path, _fileName));
  }

  Future<List<Song>> load() async {
    // The web build has no application support folder. Its library is what the
    // online sources bring in this session, so there is nothing to read.
    if (kIsWeb) return const [];

    try {
      await _adoptLibraryOfOlderVersion();

      final file = await _file();
      if (!await file.exists()) return const [];

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map((entry) => Song.fromMap(withoutLegacyNames(entry)))
          .where((song) => song.uri.isNotEmpty)
          .toList(growable: false);
    } catch (error, stackTrace) {
      Log.error('读取音乐库失败: $error\n$stackTrace');
      return const [];
    }
  }

  Future<void> save(List<Song> songs) async {
    // The web build keeps no file, so the library of this session is the one
    // the controllers already hold.
    if (kIsWeb) return;

    try {
      final file = await _file();
      final data = songs.map((song) => song.toJson()).toList(growable: false);
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (error, stackTrace) {
      // The library is a cache of what is on disk. A platform without a file
      // system, or a full disk, must not take the player down with it.
      Log.error('保存音乐库失败: $error\n$stackTrace');
    }
  }

  Future<void> clear() async {
    if (kIsWeb) return;

    try {
      final file = await _file();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (error, stackTrace) {
      Log.error('清空音乐库失败: $error\n$stackTrace');
    }
  }

  /// Moves the library of an older version into the folder of the app.
  ///
  /// An older version kept the library in the documents folder of the user.
  /// That folder belongs to the user, and it is not where the data of the app
  /// belongs, so the library moves the first time the app reads it.
  Future<void> _adoptLibraryOfOlderVersion() async {
    final file = await _file();
    if (await file.exists()) return;

    final older = await _olderFile();
    if (older == null) return;

    await older.copy(file.path);
    await older.delete();
    Log.info('音乐库已迁入应用目录: ${file.path}');
  }

  /// The library of the older version, when there is one.
  Future<File?> _olderFile() async {
    try {
      final documents =
          await (_documentsDirectory?.call() ??
              getApplicationDocumentsDirectory());
      final file = File(path.join(documents.path, _fileName));
      return await file.exists() ? file : null;
    } catch (error) {
      // A platform without a documents folder simply has no older library.
      Log.info('没有旧音乐库可迁移: $error');
      return null;
    }
  }
}

/// The words an older version wrote when a file carried no name.
///
/// The library of an older version wrote these words instead of leaving the
/// name empty, so a reader saw them in the language of that version. The
/// interface writes a missing name in the language of the app now, so the old
/// words are dropped when the library is read.
const _legacyNames = {'Unknown Artist', 'Unknown Album'};

/// A song without the words an older version wrote for a missing name.
///
/// The name of a file that carries no artist or no album is empty, and the
/// interface writes the missing name in the language of the app.
Map<String, dynamic> withoutLegacyNames(Map<String, dynamic> entry) {
  final cleaned = Map<String, dynamic>.of(entry);
  for (final field in const ['artist', 'album']) {
    final value = cleaned[field];
    if (value is String && _legacyNames.contains(value)) {
      cleaned[field] = '';
    }
  }
  return cleaned;
}
