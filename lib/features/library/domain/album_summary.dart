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
