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

  /// The sources kept out of the page because their health is too low.
  ///
  /// Filled by the controller from the health gate, never by the filter panel:
  /// it is an automatic rule, so it is not a group, is not counted by
  /// [activeGroups] and survives "clear all".
  final Set<String> excludeSources;
  final Set<String> formats;
  final Set<LibraryDurationBucket> durations;
  final Set<LibraryAddedWindow> added;
  final Set<String> languages;
  final Set<ContentKind> kinds;

  /// Whether tracks whose duration is unknown stay out of the list.
  ///
  /// A row with no duration is dirty data rather than a track the reader can
  /// play or time; it is hidden by default, and the toolbar says how many are
  /// hidden and offers to show them. This is a display rule, not a group: it
  /// is not counted by [isEmpty] and survives a "clear all".
  final bool hideMissingDuration;

  /// Whether tracks of three seconds or less stay out of the list.
  ///
  /// A track of one or two seconds is a sample, a loop or a fragment rather
  /// than something to listen to, and the archives the library reads carry
  /// thousands of them; the row is out of the table by default and the short
  /// group in the filter panel brings it back. An album still opens whole:
  /// its own query does not read this rule.
  final bool excludeShortTracks;

  /// The longest track the "very short" group leaves out, in milliseconds.
  static const int veryShortMilliseconds = 3000;

  const LibraryFilter({
    this.status = LibraryStatusFilter.all,
    this.genres = const {},
    this.decades = const {},
    this.artists = const {},
    this.sources = const {},
    this.excludeSources = const {},
    this.formats = const {},
    this.durations = const {},
    this.added = const {},
    this.languages = const {},
    this.kinds = const {},
    this.hideMissingDuration = true,
    this.excludeShortTracks = true,
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
  /// The scope always names a kind, and the two duration rules are display
  /// rules that stay on between visits, so neither is counted here: the
  /// filter button and the chips speak about the groups the reader picks.
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

  /// Whether this scope is the song list and the very short rows stay out.
  ///
  /// A sound effect is a second long by nature, so the rule only applies when
  /// the scope is exactly the songs, the same way [hidesMissingDuration] does.
  bool get hidesShortTracks =>
      excludeShortTracks &&
      kinds.length == 1 &&
      kinds.contains(ContentKind.music);

  /// Whether this scope is the song list and the reader keeps dirty rows out.
  ///
  /// A live radio stream carries no duration by nature, so the rule only
  /// applies when the scope is exactly the songs; the podcast, audiobook and
  /// radio scopes keep their rows whatever their duration says.
  bool get hidesMissingDuration =>
      hideMissingDuration &&
      kinds.length == 1 &&
      kinds.contains(ContentKind.music);

  /// The same filter with every group cleared but the content scope.
  ///
  /// The two duration rules are display rules rather than groups, so a
  /// reader who turned one off keeps it off when the groups are cleared.
  LibraryFilter withoutGroups() => LibraryFilter(
    kinds: kinds,
    excludeSources: excludeSources,
    hideMissingDuration: hideMissingDuration,
    excludeShortTracks: excludeShortTracks,
  );

  LibraryFilter copyWith({
    LibraryStatusFilter? status,
    Set<String>? genres,
    Set<int>? decades,
    Set<String>? artists,
    Set<String>? sources,
    Set<String>? excludeSources,
    Set<String>? formats,
    Set<LibraryDurationBucket>? durations,
    Set<LibraryAddedWindow>? added,
    Set<String>? languages,
    Set<ContentKind>? kinds,
    bool? hideMissingDuration,
    bool? excludeShortTracks,
  }) => LibraryFilter(
    status: status ?? this.status,
    genres: genres ?? this.genres,
    decades: decades ?? this.decades,
    artists: artists ?? this.artists,
    sources: sources ?? this.sources,
    excludeSources: excludeSources ?? this.excludeSources,
    formats: formats ?? this.formats,
    durations: durations ?? this.durations,
    added: added ?? this.added,
    languages: languages ?? this.languages,
    kinds: kinds ?? this.kinds,
    hideMissingDuration: hideMissingDuration ?? this.hideMissingDuration,
    excludeShortTracks: excludeShortTracks ?? this.excludeShortTracks,
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
      setEquals(other.kinds, kinds) &&
      other.hideMissingDuration == hideMissingDuration &&
      other.excludeShortTracks == excludeShortTracks;

  @override
  int get hashCode => Object.hash(
    status,
    Object.hashAllUnordered(genres),
    Object.hashAllUnordered(decades),
    Object.hashAllUnordered(artists),
    Object.hashAllUnordered(sources),
    Object.hashAllUnordered(excludeSources),
    Object.hashAllUnordered(formats),
    Object.hashAllUnordered(durations),
    Object.hashAllUnordered(added),
    Object.hashAllUnordered(languages),
    Object.hashAllUnordered(kinds),
    hideMissingDuration,
    excludeShortTracks,
  );
}
