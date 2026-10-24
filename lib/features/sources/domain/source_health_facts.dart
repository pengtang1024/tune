import 'package:tune/domain/models/song.dart';

/// The per-source facts the health score reads from the library.
///
/// A source with no tracks has no entry; callers use [neutral] so an empty
/// source is neither rewarded nor punished for data it has not produced.
class SourceHealthFacts {
  final double playable;
  final double artwork;
  final double metadata;
  final double activity;

  const SourceHealthFacts({
    required this.playable,
    required this.artwork,
    required this.metadata,
    required this.activity,
  });

  static const neutral = SourceHealthFacts(
    playable: 0.5,
    artwork: 0.5,
    metadata: 0.5,
    activity: 0.5,
  );
}

/// Counts the four source facts in one pass over the library.
///
/// A track is playable when it has a local file or a stream address, has
/// artwork when it has a cover, and its metadata is the weighted share of
/// artist, album and year. Activity is the share of the source's tracks the
/// reader marked with a heart.
Map<String, SourceHealthFacts> sourceHealthFactsOf(
  List<Song> songs, {
  Set<String> favoriteUris = const {},
}) {
  final totals = <String, int>{};
  final playable = <String, int>{};
  final artwork = <String, int>{};
  final artist = <String, int>{};
  final album = <String, int>{};
  final year = <String, int>{};
  final liked = <String, int>{};
  final hasFavorites = favoriteUris.isNotEmpty;

  for (final song in songs) {
    final id = song.sourceId ?? 'local';
    totals[id] = (totals[id] ?? 0) + 1;
    if (song.hasLocalFile || (song.streamUrl?.isNotEmpty ?? false)) {
      playable[id] = (playable[id] ?? 0) + 1;
    }
    if (song.hasArtwork) artwork[id] = (artwork[id] ?? 0) + 1;
    if (song.artist.trim().isNotEmpty) artist[id] = (artist[id] ?? 0) + 1;
    if (song.album.trim().isNotEmpty) album[id] = (album[id] ?? 0) + 1;
    if ((song.year ?? 0) > 0) year[id] = (year[id] ?? 0) + 1;
    if (favoriteUris.contains(song.uri)) liked[id] = (liked[id] ?? 0) + 1;
  }

  return {
    for (final entry in totals.entries)
      entry.key: SourceHealthFacts(
        playable: (playable[entry.key] ?? 0) / entry.value,
        artwork: (artwork[entry.key] ?? 0) / entry.value,
        // Artist is the one fact every playable card needs; album and year
        // make a source nicer to browse but are often missing from open
        // catalogs, so they only fill in the rest.
        metadata:
            0.6 * (artist[entry.key] ?? 0) / entry.value +
            0.25 * (album[entry.key] ?? 0) / entry.value +
            0.15 * (year[entry.key] ?? 0) / entry.value,
        // Before the first heart every source would score zero here; that is
        // not a signal about the source, so the dimension stays neutral.
        activity: hasFavorites ? (liked[entry.key] ?? 0) / entry.value : 0.5,
      ),
  };
}
