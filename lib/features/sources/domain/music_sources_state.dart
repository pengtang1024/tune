import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/sources/domain/source_scan_health.dart';

class MusicSourcesState {
  final List<MusicSourceConfig> sources;

  /// Last successful scan persisted by the source store, used to show a
  /// useful status before the first scan of this session finishes.
  final Map<String, DateTime> lastScanAt;

  /// The recent scan outcomes that feed the stability dimension.
  final Map<String, SourceScanHealthHistory> healthHistory;

  const MusicSourcesState({
    this.sources = const [],
    this.lastScanAt = const {},
    this.healthHistory = const {},
  });

  MusicSourceConfig? byId(String id) {
    for (final source in sources) {
      if (source.id == id) return source;
    }
    return null;
  }

  List<MusicSourceConfig> get enabled =>
      sources.where((source) => source.enabled).toList(growable: false);

  bool get hasEnabledRemote => enabled.any((source) => !source.isLocal);

  MusicSourcesState copyWith({
    List<MusicSourceConfig>? sources,
    Map<String, DateTime>? lastScanAt,
    Map<String, SourceScanHealthHistory>? healthHistory,
  }) {
    return MusicSourcesState(
      sources: sources ?? this.sources,
      lastScanAt: lastScanAt ?? this.lastScanAt,
      healthHistory: healthHistory ?? this.healthHistory,
    );
  }
}
