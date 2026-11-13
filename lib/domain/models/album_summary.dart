import 'package:tune/domain/models/content_kind.dart';

/// The key an album is grouped by.
///
/// A song belongs to the album of its artist. A show or a book is one album
/// even when every episode names a different artist, so a spoken track is
/// grouped by the source that publishes it instead.
String albumKeyOf({
  required String album,
  required String artist,
  String? sourceId,
}) {
  final name = album.trim().toLowerCase();
  if (name.isEmpty) return '\u0000unknown';
  if (isSpokenWordSource(sourceId)) {
    return '$name\u0000src\u0000${sourceId ?? ''}';
  }
  return '$name\u0000${artist.trim().toLowerCase()}';
}

/// One album of the library, without its tracks.
///
/// The album view only needs the name, the artist, the count and a cover to
/// draw a card. The tracks are read when the reader opens the album, so a
/// library of a hundred thousand tracks never materializes every album at
/// once.
class AlbumSummary {
  final String key;
  final String name;
  final String artist;
  final int trackCount;
  final String? coverPath;
  final String? coverUrl;

  const AlbumSummary({
    required this.key,
    required this.name,
    required this.artist,
    required this.trackCount,
    this.coverPath,
    this.coverUrl,
  });

  /// Whether the group holds the tracks that have no album at all.
  bool get isUnknown => name.isEmpty;
}
