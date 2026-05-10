import 'dart:io';
import 'package:tune/domain/models/song.dart';

class M3uExporter {
  static Future<File> exportPlaylist(List<Song> songs, String filePath, String playlistName) async {
    final file = File(filePath);
    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');
    buffer.writeln('#PLAYLIST:$playlistName');

    for (final song in songs) {
      final durationSeconds = song.duration ~/ 1000;
      buffer.writeln('#EXTINF:$durationSeconds,${song.artist} - ${song.title}');
      buffer.writeln(song.uri);
    }

    await file.writeAsString(buffer.toString());
    return file;
  }

  static Future<List<Song>> importPlaylist(String content, List<Song> library) async {
    final result = <Song>[];
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('#') || line.isEmpty) continue;

      final uri = line;
      final match = library.where((s) => s.uri == uri).firstOrNull;
      if (match != null) {
        result.add(match);
      }
    }

    return result;
  }
}
