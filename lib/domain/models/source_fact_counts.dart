/// The raw counts one source contributes to the library.
///
/// These are counted in the database over the whole table, not over the window
/// the page draws: a source with five thousand tracks must not be judged by
/// whichever thousand rows happen to be loaded, and a rule that hides rows must
/// not change the numbers that decide what to hide.
class SourceFactCounts {
  final int total;
  final int playable;
  final int artwork;
  final int artist;
  final int album;
  final int year;
  final int liked;

  const SourceFactCounts({
    required this.total,
    required this.playable,
    required this.artwork,
    required this.artist,
    required this.album,
    required this.year,
    required this.liked,
  });

  static const empty = SourceFactCounts(
    total: 0,
    playable: 0,
    artwork: 0,
    artist: 0,
    album: 0,
    year: 0,
    liked: 0,
  );

  bool get isEmpty => total == 0;

  /// A rate that reads 0 for an empty source instead of dividing by zero.
  double rate(int count) => total == 0 ? 0 : count / total;
}
