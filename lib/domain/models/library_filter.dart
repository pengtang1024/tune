import 'package:flutter/foundation.dart';
import 'package:tune/domain/models/content_kind.dart';

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
  final Set<ContentKind> kinds;

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
    this.kinds = const {},
  });

  static const LibraryFilter empty = LibraryFilter();

  /// The library a reader opens: songs, and nothing else.
  ///
  /// The content kind is a scope rather than a filter: it is never empty, so
  /// a station or a show cannot fall back into the song table by accident.
  /// The controller fills it in for any filter that arrives without one.
  static const LibraryFilter songs = LibraryFilter(
    kinds: {ContentKind.music},
  );

  /// Whether nothing narrows the page besides the content scope.
  ///
  /// The scope always names a kind, so it is not counted here: the filter
  /// button and the chips speak about the groups the reader picks.
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

  /// The same filter with every group cleared but the content scope.
  LibraryFilter withoutGroups() => LibraryFilter(kinds: kinds);

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
    Set<ContentKind>? kinds,
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
    kinds: kinds ?? this.kinds,
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
      setEquals(other.languages, languages) &&
      setEquals(other.kinds, kinds);

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
    Object.hashAllUnordered(kinds),
  );
}
