import 'package:flutter/foundation.dart';

/// What the library page shows beyond the search word.
///
/// Every set is an OR inside its group and an AND across groups: a reader
/// who picks Jazz and Rock, then 1990s, sees the jazz and rock tracks of
/// the nineties. An empty set means the group does not narrow anything.
enum LibraryStatusFilter { all, liked, withLyrics, withoutLyrics, instrumental }

/// The duration buckets the filter panel offers.
enum LibraryDurationBucket { short, medium, long, epic }

/// The windows of the "added" group.
enum LibraryAddedWindow { lastWeek, lastMonth, lastYear, older }

@immutable
class LibraryFilter {
  final LibraryStatusFilter status;
  final Set<String> genres;
  final Set<int> decades;
  final Set<String> artists;
  final Set<String> sources;
  final Set<String> formats;
  final Set<LibraryDurationBucket> durations;
  final Set<LibraryAddedWindow> added;
  final Set<String> languages;

  const LibraryFilter({
    this.status = LibraryStatusFilter.all,
    this.genres = const {},
    this.decades = const {},
    this.artists = const {},
    this.sources = const {},
    this.formats = const {},
    this.durations = const {},
    this.added = const {},
    this.languages = const {},
  });

  static const LibraryFilter empty = LibraryFilter();

  bool get isEmpty =>
      status == LibraryStatusFilter.all &&
      genres.isEmpty &&
      decades.isEmpty &&
      artists.isEmpty &&
      sources.isEmpty &&
      formats.isEmpty &&
      durations.isEmpty &&
      added.isEmpty &&
      languages.isEmpty;

  /// How many groups narrow the page; the filter button shows it.
  int get activeGroups => [
    status != LibraryStatusFilter.all,
    genres.isNotEmpty,
    decades.isNotEmpty,
    artists.isNotEmpty,
    sources.isNotEmpty,
    formats.isNotEmpty,
    durations.isNotEmpty,
    added.isNotEmpty,
    languages.isNotEmpty,
  ].where((active) => active).length;

  LibraryFilter copyWith({
    LibraryStatusFilter? status,
    Set<String>? genres,
    Set<int>? decades,
    Set<String>? artists,
    Set<String>? sources,
    Set<String>? formats,
    Set<LibraryDurationBucket>? durations,
    Set<LibraryAddedWindow>? added,
    Set<String>? languages,
  }) => LibraryFilter(
    status: status ?? this.status,
    genres: genres ?? this.genres,
    decades: decades ?? this.decades,
    artists: artists ?? this.artists,
    sources: sources ?? this.sources,
    formats: formats ?? this.formats,
    durations: durations ?? this.durations,
    added: added ?? this.added,
    languages: languages ?? this.languages,
  );

  @override
  bool operator ==(Object other) =>
      other is LibraryFilter &&
      other.status == status &&
      setEquals(other.genres, genres) &&
      setEquals(other.decades, decades) &&
      setEquals(other.artists, artists) &&
      setEquals(other.sources, sources) &&
      setEquals(other.formats, formats) &&
      setEquals(other.durations, durations) &&
      setEquals(other.added, added) &&
      setEquals(other.languages, languages);

  @override
  int get hashCode => Object.hash(
    status,
    Object.hashAllUnordered(genres),
    Object.hashAllUnordered(decades),
    Object.hashAllUnordered(artists),
    Object.hashAllUnordered(sources),
    Object.hashAllUnordered(formats),
    Object.hashAllUnordered(durations),
    Object.hashAllUnordered(added),
    Object.hashAllUnordered(languages),
  );
}
