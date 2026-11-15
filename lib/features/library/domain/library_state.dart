import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/domain/models/album_summary.dart';
import 'package:tune/domain/models/library_filter.dart';
import 'package:tune/domain/models/library_sort.dart';

enum LibraryScanStatus { idle, scanning, completed, error }

class LibraryState {
  final List<Song> songs;
  final String query;

  /// What the page narrows beyond the search word (docs/library-browse.md).
  final LibraryFilter filter;

  /// The column the page is ordered by.
  final LibrarySort sort;
  final LibraryScanStatus scanStatus;
  final double scanProgress;
  final String? statusMessage;
  final String? errorMessage;
  final bool isLoading;

  /// Last scan outcome per source. One source failing must not hide results
  /// from the sources that succeeded.
  final Map<String, SourceScanSummary> sourceSummaries;

  /// How many tracks the library holds on disk.
  ///
  /// It is larger than [songs] when the library is read a window at a time.
  /// The search word and the filter do not change it: [matching] reports
  /// those.
  final int total;

  /// How many tracks the word and the filter match.
  ///
  /// The list holds a window of them, so the count beside the sort menu reads
  /// this instead of the length of [songs].
  final int matching;

  /// How many tracks are not music.
  ///
  /// The page offers the stations and the shows in a menu; a library that
  /// holds only songs has no use for the entry.
  final int otherKindCount;

  /// Whether another window of the library is waiting on disk.
  final bool hasMore;

  /// How many matching tracks the page keeps out because their duration is
  /// unknown. The toolbar states it and offers to show them.
  final int hiddenMissingDuration;

  /// The albums of the library, without their tracks.
  final List<AlbumSummary> albums;

  const LibraryState({
    this.songs = const [],
    this.query = '',
    this.filter = LibraryFilter.empty,
    this.sort = LibrarySort.recent,
    this.scanStatus = LibraryScanStatus.idle,
    this.scanProgress = 0,
    this.statusMessage,
    this.errorMessage,
    this.isLoading = false,
    this.sourceSummaries = const {},
    this.total = 0,
    this.matching = 0,
    this.otherKindCount = 0,
    this.hasMore = false,
    this.hiddenMissingDuration = 0,
    this.albums = const [],
  });

  static const LibraryState initial = LibraryState();

  bool get hasSongs => songs.isNotEmpty;
  bool get isScanning => scanStatus == LibraryScanStatus.scanning;

  /// The one source the toolbar narrows by; `null` shows every source.
  ///
  /// Derived from [filter]: the filter is the only authority, so the page
  /// cannot hold two answers that disagree.
  String? get sourceFilter =>
      filter.sources.length == 1 ? filter.sources.first : null;

  /// Whether the page is narrowed by something other than the search word.
  bool get hasFilter => !filter.isEmpty;

  /// The tracks the page shows.
  ///
  /// The storage already applies the query and the source filter, so this
  /// filter is idempotent: a window that came from the database passes
  /// through unchanged, and a hand-made state (a test, a cached list) is
  /// still narrowed the way the page expects.
  List<Song> get filteredSongs => filteredSongsOf(
    songs: songs,
    query: query,
    sourceFilter: sourceFilter,
  );

  LibraryState copyWith({
    List<Song>? songs,
    String? query,
    LibraryFilter? filter,
    LibrarySort? sort,
    LibraryScanStatus? scanStatus,
    double? scanProgress,
    Object? statusMessage = _unset,
    Object? errorMessage = _unset,
    bool? isLoading,
    Map<String, SourceScanSummary>? sourceSummaries,
    int? total,
    int? matching,
    int? otherKindCount,
    bool? hasMore,
    int? hiddenMissingDuration,
    List<AlbumSummary>? albums,
  }) {
    return LibraryState(
      songs: songs ?? this.songs,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      scanStatus: scanStatus ?? this.scanStatus,
      scanProgress: scanProgress ?? this.scanProgress,
      statusMessage: identical(statusMessage, _unset)
          ? this.statusMessage
          : statusMessage as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      isLoading: isLoading ?? this.isLoading,
      sourceSummaries: sourceSummaries ?? this.sourceSummaries,
      total: total ?? this.total,
      matching: matching ?? this.matching,
      otherKindCount: otherKindCount ?? this.otherKindCount,
      hasMore: hasMore ?? this.hasMore,
      hiddenMissingDuration:
          hiddenMissingDuration ?? this.hiddenMissingDuration,
      albums: albums ?? this.albums,
    );
  }
}

const Object _unset = Object();

/// The tracks the library page shows.
///
/// The tracks of the chosen source that match the search. The page reads it
/// through this function instead of walking the library by itself, so there
/// is one rule for what the page shows.
List<Song> filteredSongsOf({
  required List<Song> songs,
  required String query,
  required String? sourceFilter,
}) {
  final sourceSongs = sourceFilter == null
      ? songs
      : songs
            .where((song) => (song.sourceId ?? 'local') == sourceFilter)
            .toList(growable: false);
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return sourceSongs;

  return sourceSongs
      .where((song) {
        return song.title.toLowerCase().contains(normalized) ||
            song.artist.toLowerCase().contains(normalized) ||
            song.album.toLowerCase().contains(normalized);
      })
      .toList(growable: false);
}
