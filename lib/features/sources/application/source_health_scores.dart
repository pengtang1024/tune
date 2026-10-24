import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/domain/source_health.dart';

/// The health score of every configured source, between 0 and 1.
///
/// This is the output of the health system, not its weights: the source page
/// owns how the dimensions are weighted, and a recommendation only consumes
/// the resulting score. A source that is off or broken therefore loses some
/// recommendation weight without teaching the recommender a second health
/// model.
final sourceHealthScoresProvider = Provider<Map<String, double>>((ref) {
  final sources = ref.watch(
    musicSourcesControllerProvider.select((value) => value.valueOrNull),
  );
  if (sources == null || sources.sources.isEmpty) return const {};

  final library = ref.watch(
    libraryControllerProvider.select((value) {
      final state = value.valueOrNull;
      return (
        songs: state?.songs ?? const <Song>[],
        summaries:
            state?.sourceSummaries ?? const <String, SourceScanSummary>{},
      );
    }),
  );
  final weights = ref.watch(
    settingsControllerProvider.select((state) => state.sourceHealthWeights),
  );
  final favorites = ref.watch(
    favoritesControllerProvider.select((state) => state.ids),
  );
  final service = ref.watch(musicSourceServiceProvider);
  final coverage = _coverageBySource(library.songs);
  final activity = _activityBySource(library.songs, favorites);

  return Map.unmodifiable({
    for (final source in sources.sources)
      source.id:
          SourceHealth.report(
            isLocal: source.isLocal,
            enabled: source.enabled,
            supported: service.supportsConfig(source),
            configured: service.isConfigured(source),
            summary: library.summaries[source.id],
            lastScanAt: sources.lastScanAt[source.id],
            autoScanInterval: service.autoScanIntervalFor(source),
            scanTimeout: service.scanTimeoutFor(source),
            weights: weights,
            history: sources.healthHistory[source.id],
            playable: coverage[source.id]?.playableRate ?? 0.5,
            artwork: coverage[source.id]?.artworkRate ?? 0.5,
            metadata: coverage[source.id]?.metadataRate ?? 0.5,
            activity: activity[source.id] ?? 0.5,
          ).score /
          100,
  });
});

class _SourceCoverage {
  int total = 0;
  int playable = 0;
  int artwork = 0;
  int metadata = 0;

  double get playableRate => total == 0 ? 0.5 : playable / total;
  double get artworkRate => total == 0 ? 0.5 : artwork / total;
  double get metadataRate => total == 0 ? 0.5 : metadata / total;
}

Map<String, _SourceCoverage> _coverageBySource(List<Song> songs) {
  final coverage = <String, _SourceCoverage>{};
  for (final song in songs) {
    final id = song.sourceId ?? 'local';
    final item = coverage.putIfAbsent(id, _SourceCoverage.new);
    item.total++;
    if (song.hasLocalFile || (song.streamUrl?.isNotEmpty ?? false)) {
      item.playable++;
    }
    if (song.hasArtwork) item.artwork++;
    if (song.artist.trim().isNotEmpty) item.metadata++;
  }
  return coverage;
}

Map<String, double> _activityBySource(List<Song> songs, Set<String> favorites) {
  final total = <String, int>{};
  final liked = <String, int>{};
  for (final song in songs) {
    final id = song.sourceId ?? 'local';
    total[id] = (total[id] ?? 0) + 1;
    if (favorites.contains(song.uri)) {
      liked[id] = (liked[id] ?? 0) + 1;
    }
  }
  return {
    for (final entry in total.entries)
      entry.key: entry.value == 0 ? 0.5 : (liked[entry.key] ?? 0) / entry.value,
  };
}

/// The health score of one source, for a caller that already has the map.
double sourceHealthOf(String? sourceId, Map<String, double> scores) {
  if (sourceId == null || sourceId.isEmpty || sourceId == 'local') return 1;
  return scores[sourceId] ?? 0.5;
}

/// The health score that belongs to a track.
double trackSourceHealth(Song song, Map<String, double> scores) {
  return sourceHealthOf(song.sourceId, scores);
}
