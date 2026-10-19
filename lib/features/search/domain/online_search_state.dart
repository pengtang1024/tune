import 'package:tune/domain/models/source_scan_result.dart';

/// Transient results of an on-demand online source search.
///
/// These songs are deliberately not written into the library cache; they are
/// only handed to the playback queue when the user chooses one.
class OnlineSearchState {
  final String query;
  final bool isSearching;
  final Map<String, SourceScanResult> results;
  final Map<String, double> progress;
  final String? message;

  const OnlineSearchState({
    this.query = '',
    this.isSearching = false,
    this.results = const {},
    this.progress = const {},
    this.message,
  });

  bool get hasQuery => query.isNotEmpty;

  int get totalSongs =>
      results.values.fold(0, (total, result) => total + result.songs.length);

  bool get hasResults => totalSongs > 0;

  Iterable<SourceScanResult> get orderedResults => results.values;

  OnlineSearchState copyWith({
    String? query,
    bool? isSearching,
    Map<String, SourceScanResult>? results,
    Map<String, double>? progress,
    Object? message = _keep,
  }) {
    return OnlineSearchState(
      query: query ?? this.query,
      isSearching: isSearching ?? this.isSearching,
      results: results ?? this.results,
      progress: progress ?? this.progress,
      message: identical(message, _keep) ? this.message : message as String?,
    );
  }
}

const Object _keep = Object();
