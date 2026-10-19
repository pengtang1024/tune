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
          .map(Song.fromMap)
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
