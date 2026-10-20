import 'dart:convert';

import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';

/// Reads a value out of a decoded answer by its path.
///
/// The path is a list of steps separated by dots: `data.songs` takes the key
/// `songs` out of the map under `data`, `data.songs.0` takes its first entry.
/// A step that is not there is an empty value, not an error — the reader
/// writes these paths by hand and one wrong letter should not stop the scan.
Object? readJsonPath(Object? root, String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return root;

  Object? current = root;
  for (final step in trimmed.split('.')) {
    if (step.isEmpty) continue;

    if (current is Map) {
      current = current[step];
      continue;
    }
    if (current is List) {
      final index = int.tryParse(step);
      if (index == null || index < 0 || index >= current.length) return null;
      current = current[index];
      continue;
    }
    return null;
  }
  return current;
}

/// The text of a value, when it is one.
String jsonText(Object? value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  if (value is num || value is bool) return '$value';
  return '';
}

/// The seconds of a value, when it says how long something is.
///
/// A plain number is a number of seconds; `3:45` is read as minutes and
/// seconds, the way a duration is written in most places.
int jsonSeconds(Object? value) {
  if (value is num) return value.toInt();
  final text = jsonText(value);
  if (text.isEmpty) return 0;

  final parts = text.split(':');
  if (parts.length == 2) {
    final minutes = int.tryParse(parts[0].trim());
    final seconds = int.tryParse(parts[1].trim());
    if (minutes == null || seconds == null) return 0;
    return minutes * 60 + seconds;
  }
  return int.tryParse(text) ?? 0;
}

/// A decoded JSON value, or an empty map when the text is not one.
Object? decodeJsonValue(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  try {
    return jsonDecode(trimmed);
  } on FormatException {
    throw MusicSourceFailure(AppStrings.instance.jsonInvalidObject);
  }
}

/// A decoded JSON object, or an empty map when the text is not one.
Map<String, dynamic> decodeJsonObject(String raw) {
  final decoded = decodeJsonValue(raw);
  if (decoded == null) return const {};
  if (decoded is! Map<String, dynamic>) {
    throw MusicSourceFailure(AppStrings.instance.jsonInvalidObject);
  }
  return decoded;
}

/// The headers of a request, read from a JSON object.
///
/// A header is a string key and a string value; the reader writes them as
/// `{"Authorization":"Bearer …"}`.
Map<String, String> parseJsonHeaders(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const {};

  final decoded = decodeJsonObject(trimmed);
  return {
    for (final entry in decoded.entries)
      if (entry.value != null) entry.key: '${entry.value}',
  };
}

/// Writes the search keyword into the places that ask for it.
///
/// The reader marks the spot with `${query}`: in the address of the request,
/// in a header or in the body. The keyword goes in as text, so it never
/// becomes part of the shape of the answer.
Object? replaceJsonKeyword(Object? value, String keyword) {
  if (value is String) return value.replaceAll('\${query}', keyword);
  if (value is Map) {
    return {
      for (final entry in value.entries)
        '${entry.key}': replaceJsonKeyword(entry.value, keyword),
    };
  }
  if (value is List) {
    return [for (final item in value) replaceJsonKeyword(item, keyword)];
  }
  return value;
}
