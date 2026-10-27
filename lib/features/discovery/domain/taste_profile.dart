import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/taste_profile_keys.dart';
import 'package:tune/features/discovery/domain/track_listening.dart';

export 'package:tune/features/discovery/domain/taste_profile_keys.dart';

/// A normalized picture of what the reader likes.
///
/// The profile is built from the tracks the reader marked with a heart and,
/// when the reader asked for it, from the local listening aggregates. It is
/// derived on every visit and never stored: the marks and the counters are
/// the facts, the weights are only a reading of them.
class TasteProfile {
  /// Normalized artist keys, between 0 and 1.
  final Map<String, double> artists;

  /// Normalized genre keys, between 0 and 1.
  final Map<String, double> genres;

  /// Normalized decades, between 0 and 1.
  final Map<int, double> decades;

  /// Normalized album keys, between 0 and 1.
  final Map<String, double> albums;

  /// How many tracks of the library are marked.
  final int favoriteCount;

  /// How many plays the profile was allowed to learn from.
  final int listenCount;

  const TasteProfile({
    this.artists = const {},
    this.genres = const {},
    this.decades = const {},
    this.albums = const {},
    this.favoriteCount = 0,
    this.listenCount = 0,
  });

  static const empty = TasteProfile();

  /// Builds a profile from weights that were already counted.
  ///
  /// A library of a hundred thousand tracks is counted by the database; the
  /// profile only normalizes the totals, so the page never loads every track
  /// to learn the same numbers.
  factory TasteProfile.fromWeights({
    Map<String, double> artists = const {},
    Map<String, double> genres = const {},
    Map<int, double> decades = const {},
    Map<String, double> albums = const {},
    int favoriteCount = 0,
    int listenCount = 0,
  }) {
    return TasteProfile(
      artists: _normalize(artists),
      genres: _normalize(genres),
      decades: _normalizeDecades(decades),
      albums: _normalize(albums),
      favoriteCount: favoriteCount,
      listenCount: listenCount,
    );
  }

  factory TasteProfile.from({
    required List<Song> library,
    required Set<String> favoriteUris,
    Map<String, TrackListening> listening = const {},
    DateTime? now,
  }) {
    final artists = <String, double>{};
    final genres = <String, double>{};
    final decades = <int, double>{};
    final albums = <String, double>{};
    final clock = now ?? DateTime.now();
    var favoriteCount = 0;
    var listenCount = 0;

    for (final song in library) {
      final rawArtist = normalizeTasteKey(song.artist);
      final artist = isGenericArtistKey(rawArtist) ? '' : rawArtist;
      final decade = decadeOf(song.year);
      final album = normalizeTasteKey(song.album);

      if (favoriteUris.contains(song.uri)) {
        favoriteCount++;
        if (artist.isNotEmpty) {
          artists.update(artist, (value) => value + 3, ifAbsent: () => 3);
        }
        for (final genre in genreKeysOf(song)) {
          genres.update(genre, (value) => value + 1.5, ifAbsent: () => 1.5);
        }
        if (decade != null) {
          decades.update(decade, (value) => value + 1, ifAbsent: () => 1);
        }
        if (album.isNotEmpty) {
          albums.update(album, (value) => value + 1, ifAbsent: () => 1);
        }
      }

      final signal = listening[song.uri];
      if (signal == null) continue;
      final weight = listenWeight(signal, clock);
      listenCount += signal.listens;
      if (weight <= 0) continue;
      if (artist.isNotEmpty) {
        artists.update(
          artist,
          (value) => value + weight,
          ifAbsent: () => weight,
        );
      }
      for (final genre in genreKeysOf(song)) {
        genres.update(
          genre,
          (value) => value + weight * 0.5,
          ifAbsent: () => weight * 0.5,
        );
      }
      if (decade != null) {
        decades.update(
          decade,
          (value) => value + weight * 0.5,
          ifAbsent: () => weight * 0.5,
        );
      }
      if (album.isNotEmpty) {
        albums.update(
          album,
          (value) => value + weight * 0.3,
          ifAbsent: () => weight * 0.3,
        );
      }
    }

    return TasteProfile(
      artists: _normalize(artists),
      genres: _normalize(genres),
      decades: _normalizeDecades(decades),
      albums: _normalize(albums),
      favoriteCount: favoriteCount,
      listenCount: listenCount,
    );
  }

  double artistWeight(String artist) {
    return artistWeightKey(normalizeTasteKey(artist));
  }

  double genreWeight(String genre) {
    return genreWeightKey(normalizeTasteKey(genre));
  }

  double artistWeightKey(String key) {
    return key.isEmpty ? 0 : artists[key] ?? 0;
  }

  double genreWeightKey(String key) {
    return key.isEmpty ? 0 : genres[key] ?? 0;
  }

  double decadeWeight(int? decade) {
    if (decade == null) return 0;
    return decades[decade] ?? 0;
  }

  double albumWeightKey(String key) {
    return key.isEmpty ? 0 : albums[key] ?? 0;
  }

  bool get isEmpty =>
      artists.isEmpty && genres.isEmpty && decades.isEmpty && albums.isEmpty;

  /// How much evidence the profile rests on, between 0 and 1.
  ///
  /// One favorite is a hint; ten favorites and a listening history are a
  /// taste. A weak profile gets more exploration slots instead of letting a
  /// single artist or decade fill the daily mix.
  double get confidence {
    final evidence = favoriteCount * 2 + listenCount / 3;
    return (evidence / 20).clamp(0.0, 1.0).toDouble();
  }

  /// The strongest artists, strongest first.
  List<String> topArtists([int count = 2]) => _top(artists, count);

  /// The strongest genres, strongest first.
  List<String> topGenres([int count = 2]) => _top(genres, count);

  /// The strongest decades, strongest first.
  List<int> topDecades([int count = 2]) => _topDecades(decades, count);

  /// A short, stable reading of the profile.
  ///
  /// The daily mix uses it as part of its seed, so changing a heart changes
  /// the mix, while rebuilding the same page does not.
  String get signature {
    final parts = <String>[
      for (final artist in _top(artists, 3))
        'a:$artist:${(artists[artist]! * 100).round()}',
      for (final album in _top(albums, 3))
        'al:$album:${(albums[album]! * 100).round()}',
      for (final genre in _top(genres, 3))
        'g:$genre:${(genres[genre]! * 100).round()}',
      for (final decade in _topDecades(decades, 3))
        'd:$decade:${(decades[decade]! * 100).round()}',
    ];
    return parts.join('|');
  }
}

Map<int, double> _normalizeDecades(Map<int, double> weights) {
  if (weights.isEmpty) return const {};
  final maximum = weights.values.reduce(
    (left, right) => left > right ? left : right,
  );
  if (maximum <= 0) return const {};
  return Map<int, double>.unmodifiable({
    for (final entry in weights.entries)
      if (entry.value > 0) entry.key: entry.value / maximum,
  });
}

Map<String, double> _normalize(Map<String, double> weights) {
  if (weights.isEmpty) return const {};
  final maximum = weights.values.reduce(
    (left, right) => left > right ? left : right,
  );
  if (maximum <= 0) return const {};
  return Map<String, double>.unmodifiable({
    for (final entry in weights.entries)
      if (entry.value > 0) entry.key: entry.value / maximum,
  });
}

List<String> _top(Map<String, double> weights, int count) {
  final entries = weights.entries.where((entry) => entry.value > 0).toList()
    ..sort((left, right) {
      final byWeight = right.value.compareTo(left.value);
      if (byWeight != 0) return byWeight;
      return left.key.compareTo(right.key);
    });
  return [for (final entry in entries.take(count)) entry.key];
}

List<int> _topDecades(Map<int, double> weights, int count) {
  final entries = weights.entries.where((entry) => entry.value > 0).toList()
    ..sort((left, right) {
      final byWeight = right.value.compareTo(left.value);
      if (byWeight != 0) return byWeight;
      return left.key.compareTo(right.key);
    });
  return [for (final entry in entries.take(count)) entry.key];
}
