import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

enum LibraryScanStatus { idle, scanning, completed, error }

class LibraryState {
  final List<Song> songs;
  final String query;

  /// `null` shows every source; otherwise only songs from this source id.
  final String? sourceFilter;
  final LibraryScanStatus scanStatus;
  final double scanProgress;
  final String? statusMessage;
  final String? errorMessage;
  final bool isLoading;

  /// Last scan outcome per source. One source failing must not hide results
  /// from the sources that succeeded.
  final Map<String, SourceScanSummary> sourceSummaries;

  const LibraryState({
    this.songs = const [],
    this.query = '',
    this.sourceFilter,
    this.scanStatus = LibraryScanStatus.idle,
    this.scanProgress = 0,
    this.statusMessage,
    this.errorMessage,
    this.isLoading = false,
    this.sourceSummaries = const {},
  });

  static const LibraryState initial = LibraryState();

  bool get hasSongs => songs.isNotEmpty;
  bool get isScanning => scanStatus == LibraryScanStatus.scanning;

  List<Song> get filteredSongs {
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

  LibraryState copyWith({
    List<Song>? songs,
    String? query,
    Object? sourceFilter = _unset,
    LibraryScanStatus? scanStatus,
    double? scanProgress,
    Object? statusMessage = _unset,
    Object? errorMessage = _unset,
    bool? isLoading,
    Map<String, SourceScanSummary>? sourceSummaries,
  }) {
    return LibraryState(
      songs: songs ?? this.songs,
      query: query ?? this.query,
      sourceFilter: identical(sourceFilter, _unset)
          ? this.sourceFilter
          : sourceFilter as String?,
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
    );
  }
}

const Object _unset = Object();
