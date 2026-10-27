import 'package:tune/features/discovery/domain/track_listening.dart';

/// The counts a library too large to load can still answer.
///
/// The database groups the marked tracks by artist, genre, album and decade
/// and joins the listening aggregates to their facts; the page normalizes the
/// totals instead of walking every track.
class TasteAggregates {
  final Map<String, int> artists;
  final Map<String, int> genres;
  final Map<String, int> albums;
  final Map<int, int> decades;
  final List<TasteSignalRow> signals;

  const TasteAggregates({
    this.artists = const {},
    this.genres = const {},
    this.albums = const {},
    this.decades = const {},
    this.signals = const [],
  });

  static const empty = TasteAggregates();
}

/// One listening row joined with the facts of its track.
class TasteSignalRow {
  final String artist;
  final String genre;
  final String album;
  final int year;
  final TrackListening signal;

  const TasteSignalRow({
    required this.artist,
    required this.genre,
    required this.album,
    required this.year,
    required this.signal,
  });
}
