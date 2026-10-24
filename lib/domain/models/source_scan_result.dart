import 'package:tune/domain/models/song.dart';

enum SourceScanStatus { success, failed, skipped, needsConfiguration }

/// Outcome of scanning a single music source.
class SourceScanResult {
  final String sourceId;
  final SourceScanStatus status;
  final List<Song> songs;
  final String? message;
  final DateTime scannedAt;
  final Duration elapsed;

  SourceScanResult({
    required this.sourceId,
    required this.status,
    this.songs = const [],
    this.message,
    DateTime? scannedAt,
    this.elapsed = Duration.zero,
  }) : scannedAt = scannedAt ?? DateTime.now();

  bool get isSuccess => status == SourceScanStatus.success;

  /// Skipped sources reuse the cached songs; only a success replaces them.
  bool get shouldKeepPreviousSongs => !isSuccess;

  int get songCount => songs.length;
}

/// What a source would make of a configuration, before it is kept.
///
/// The reader tries a mapping out: the interface is asked once, the tracks it
/// holds are shown, and the paths the app could read are offered to fill the
/// form in. Nothing is saved, so a wrong guess costs nothing.
class SourcePreview {
  /// The tracks the answer holds, as the mapping reads them.
  final List<Song> songs;

  /// The settings the app would fill in, keyed by the setting they belong to.
  final Map<String, String> suggestions;

  /// The reason the answer brought nothing, when it brought nothing.
  final String? message;

  const SourcePreview({
    this.songs = const [],
    this.suggestions = const {},
    this.message,
  });
}

/// Compact, UI-friendly summary of a source scan.
class SourceScanSummary {
  final String sourceId;
  final SourceScanStatus status;
  final int songCount;
  final String? message;
  final DateTime scannedAt;

  /// How long the last scan took. Zero when the summary came from a cache or
  /// from a test that did not care.
  final Duration elapsed;

  const SourceScanSummary({
    required this.sourceId,
    required this.status,
    required this.songCount,
    required this.scannedAt,
    this.message,
    this.elapsed = Duration.zero,
  });

  factory SourceScanSummary.fromResult(SourceScanResult result) {
    return SourceScanSummary(
      sourceId: result.sourceId,
      status: result.status,
      songCount: result.songCount,
      scannedAt: result.scannedAt,
      message: result.message,
      elapsed: result.elapsed,
    );
  }
}
