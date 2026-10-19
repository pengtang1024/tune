import 'package:tune/domain/models/music_source.dart';

class MusicSourcesState {
  final List<MusicSourceConfig> sources;

  /// Last successful scan persisted by the source store, used to show a
  /// useful status before the first scan of this session finishes.
  final Map<String, DateTime> lastScanAt;

  const MusicSourcesState({
    this.sources = const [],
    this.lastScanAt = const {},
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
  }) {
    return MusicSourcesState(
      sources: sources ?? this.sources,
      lastScanAt: lastScanAt ?? this.lastScanAt,
    );
  }
}
