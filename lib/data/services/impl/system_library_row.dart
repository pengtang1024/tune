import 'package:tune/domain/models/song.dart';

/// Builds a song out of one row of the library of the system.
///
/// MediaStore and a tree picked through SAF answer with the same fields, so
/// one reader maps both of them. The address stays a `content://` URI: it is
/// what the player is handed and what names the row in the library.
Song? songOfSystemRow(Map<Object?, Object?> row) {
  final uri = row['uri'] as String?;
  if (uri == null || uri.isEmpty) return null;
  final addedSeconds = row['dateAddedSeconds'] as int? ?? 0;
  final duration = row['durationMs'] as int? ?? 0;
  return Song(
    id: uri.hashCode,
    title: row['title'] as String? ?? '',
    artist: row['artist'] as String? ?? '',
    album: row['album'] as String? ?? '',
    duration: duration,
    uri: uri,
    dateAdded: addedSeconds * 1000,
    year: row['year'] as int?,
    size: row['size'] as int?,
    type: 'audio',
    externalId: '${row['mediaId']}',
  );
}
