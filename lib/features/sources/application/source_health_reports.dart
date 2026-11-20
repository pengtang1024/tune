import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_fact_counts.dart';
import 'package:tune/domain/models/source_health_weights.dart';
import 'package:tune/domain/models/source_scan_health.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/domain/source_health.dart';
import 'package:tune/features/sources/domain/source_health_facts.dart';

/// The health report of every configured source.
///
/// This is the one place that turns the library, the favorites and the scan
/// history into health reports. The source page renders the dimensions, the
/// discovery page consumes the score, and neither builds a second model.
/// The health report of every configured source, from data the caller owns.
///
/// The provider below is the page-side reader of this function; the library
/// controller calls it too, because the gate has to ask the same question
/// before it writes a window. Two callers, one computation.
Map<String, SourceHealthReport> buildSourceHealthReports({
  required Iterable<MusicSourceConfig> sources,
  required Map<String, SourceFactCounts> facts,
  required Map<String, SourceScanSummary> summaries,
  required Map<String, DateTime> lastScanAt,
  required Map<String, SourceScanHealthHistory> history,
  required SourceHealthWeights weights,
  required Set<String> favoriteUris,
  required MusicSourceService service,
  required DateTime now,
  List<Song> songs = const [],
}) {
  final resolved = facts.isEmpty
      ? sourceHealthFactsOf(songs, favoriteUris: favoriteUris)
      : {
          for (final entry in facts.entries)
            entry.key: SourceHealthFacts.fromCounts(entry.value),
        };

  SourceHealthReport reportFor(MusicSourceConfig source) {
    final fact = resolved[source.id];
    return SourceHealth.report(
      isLocal: source.isLocal,
      enabled: source.enabled,
      supported: service.supportsConfig(source),
      configured: service.isConfigured(source),
      summary: summaries[source.id],
      lastScanAt: lastScanAt[source.id],
      autoScanInterval: service.autoScanIntervalFor(source),
      scanTimeout: service.scanTimeoutFor(source),
      expectedCount: service.scanLimitFor(source),
      weights: weights,
      history: history[source.id],
      now: now,
      hasTracks: fact != null,
      playable: fact?.playable ?? SourceHealthFacts.unknown.playable,
      artwork: fact?.artwork ?? SourceHealthFacts.unknown.artwork,
      metadata: fact?.metadata ?? SourceHealthFacts.unknown.metadata,
      activity: fact?.activity ?? SourceHealthFacts.unknown.activity,
    );
  }

  return Map.unmodifiable({
    for (final source in sources) source.id: reportFor(source),
  });
}

final sourceHealthReportsProvider = Provider<Map<String, SourceHealthReport>>((
  ref,
) {
  final sources = ref.watch(
    musicSourcesControllerProvider.select((value) => value.value),
  );
  if (sources == null || sources.sources.isEmpty) return const {};
  final library = ref.watch(
    libraryControllerProvider.select((value) {
      final state = value.value;
      return (
        songs: state?.songs ?? const <Song>[],
        facts: state?.sourceFacts ?? const <String, SourceFactCounts>{},
        summaries:
            state?.sourceSummaries ?? const <String, SourceScanSummary>{},
      );
    }),
  );
  final weights = ref.watch(
    settingsControllerProvider.select((state) => state.sourceHealthWeights),
  );
  final favoriteUris = ref.watch(
    favoritesControllerProvider.select((state) => state.ids),
  );
  return buildSourceHealthReports(
    sources: sources.sources,
    facts: library.facts,
    summaries: library.summaries,
    lastScanAt: sources.lastScanAt,
    history: sources.healthHistory,
    weights: weights,
    favoriteUris: favoriteUris,
    service: ref.watch(musicSourceServiceProvider),
    now: DateTime.now(),
    songs: library.songs,
  );
});
