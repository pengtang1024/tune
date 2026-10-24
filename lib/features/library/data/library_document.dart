import 'dart:convert';

import 'package:tune/domain/models/song.dart';

/// Reads the songs of a library document.
///
/// A document that cannot be read holds no songs: the library is a cache of
/// what the sources brought in, and a broken document must not take the player
/// down with it.
List<Song> decodeLibrary(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! List) return const [];

  return decoded
      .whereType<Map<String, dynamic>>()
      .map((entry) => Song.fromMap(withoutLegacyNames(entry)))
      .where((song) => song.uri.isNotEmpty)
      .toList(growable: false);
}

/// Writes the songs into a library document.
String encodeLibrary(List<Song> songs) =>
    jsonEncode(songs.map((song) => song.toJson()).toList(growable: false));

/// The words an older version wrote when a file carried no name.
///
/// The library of an older version wrote these words instead of leaving the
/// name empty, so a reader sees them in the language of that version. The
/// interface writes a missing name in the language of the app now, so the old
/// words are dropped when the library is read.
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

const _legacyNames = {'Unknown Artist', 'Unknown Album'};
