import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';

/// Persists the scanned library as a single JSON document.
///
/// This file is intentionally outside the controllers: both scanning and
/// startup loading should go through the same storage boundary.
class LibraryStorage {
  static const _fileName = 'scanned_songs.json';

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(path.join(directory.path, _fileName));
  }

  Future<List<Song>> load() async {
    try {
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
    final file = await _file();
    final data = songs.map((song) => song.toJson()).toList(growable: false);
    await file.writeAsString(jsonEncode(data), flush: true);
  }

  Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) {
      await file.delete();
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
