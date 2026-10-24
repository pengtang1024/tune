import 'package:tune/domain/models/song.dart';

/// A normalized picture of what the reader likes.
///
/// The profile is built from the tracks the reader marked with a heart. It is
/// derived on every visit and never stored: a heart is the fact, the weights
/// are only a reading of it.
class TasteProfile {
  /// Normalized artist keys, between 0 and 1.
  final Map<String, double> artists;

  /// Normalized genre keys, between 0 and 1.
  final Map<String, double> genres;

  /// Normalized decades, between 0 and 1.
  final Map<int, double> decades;

  /// How many tracks of the library are marked.
  final int favoriteCount;

  const TasteProfile({
    this.artists = const {},
    this.genres = const {},
    this.decades = const {},
    this.favoriteCount = 0,
  });

  static const empty = TasteProfile();

  factory TasteProfile.from({
    required List<Song> library,
    required Set<String> favoriteUris,
  }) {
    final artists = <String, double>{};
    final genres = <String, double>{};
    final decades = <int, double>{};
    var favoriteCount = 0;

    for (final song in library) {
      if (!favoriteUris.contains(song.uri)) continue;
      favoriteCount++;

      final artist = normalizeTasteKey(song.artist);
      if (artist.isNotEmpty) {
        artists.update(artist, (value) => value + 3, ifAbsent: () => 3);
      }
      for (final genre in genreKeysOf(song)) {
        genres.update(genre, (value) => value + 1.5, ifAbsent: () => 1.5);
      }
      final decade = decadeOf(song.year);
      if (decade != null) {
        decades.update(decade, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    return TasteProfile(
      artists: _normalize(artists),
      genres: _normalize(genres),
      decades: _normalizeDecades(decades),
      favoriteCount: favoriteCount,
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

  bool get isEmpty => artists.isEmpty && genres.isEmpty && decades.isEmpty;

  /// The strongest artists, strongest first.
  List<String> topArtists([int count = 2]) => _top(artists, count);

  /// The strongest genres, strongest first.
  List<String> topGenres([int count = 2]) => _top(genres, count);

  /// A short, stable reading of the profile.
  ///
  /// The daily mix uses it as part of its seed, so changing a heart changes
  /// the mix, while rebuilding the same page does not.
  String get signature {
    final parts = <String>[
      for (final artist in _top(artists, 3))
        'a:$artist:${(artists[artist]! * 100).round()}',
      for (final genre in _top(genres, 3))
        'g:$genre:${(genres[genre]! * 100).round()}',
      for (final decade in _topDecades(decades, 3))
        'd:$decade:${(decades[decade]! * 100).round()}',
    ];
    return parts.join('|');
  }
}

/// The lower-case form of an artist or genre used to compare names.
final RegExp _whitespace = RegExp(r'\s+');
final RegExp _genreSeparator = RegExp(r'\s*[/,;、]\s*');

String normalizeTasteKey(String value) {
  return value.trim().toLowerCase().replaceAll(_whitespace, ' ');
}

/// The genre keys of a track.
///
/// A source may write the genres as a list or as one line with separators.
/// Both end up as one key per genre, because "Rock/Jazz" and ["Rock", "Jazz"]
/// mean the same thing to the profile.
Iterable<String> genreValuesOf(Song song) sync* {
  final raw = song.genres?.isNotEmpty == true
      ? song.genres!
      : [if (song.genre != null) song.genre!];
  for (final value in raw) {
    for (final part in value.split(_genreSeparator)) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty) yield trimmed;
    }
  }
}

Iterable<String> genreKeysOf(Song song) sync* {
  final seen = <String>{};
  for (final value in genreValuesOf(song)) {
    final key = normalizeTasteKey(value);
    if (key.isNotEmpty && seen.add(key)) yield key;
  }
}

/// The decade of a year, or null when the year is not usable.
int? decadeOf(int? year) {
  if (year == null || year < 1900 || year > 2100) return null;
  return (year ~/ 10) * 10;
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
