import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
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
final sourceHealthReportsProvider = Provider<Map<String, SourceHealthReport>>((
  ref,
) {
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
  final favoriteUris = ref.watch(
    favoritesControllerProvider.select((state) => state.ids),
  );
  final service = ref.watch(musicSourceServiceProvider);
  final facts = sourceHealthFactsOf(library.songs, favoriteUris: favoriteUris);
  final now = DateTime.now();

  SourceHealthReport reportFor(MusicSourceConfig source) {
    final fact = facts[source.id];
    return SourceHealth.report(
      isLocal: source.isLocal,
      enabled: source.enabled,
      supported: service.supportsConfig(source),
      configured: service.isConfigured(source),
      summary: library.summaries[source.id],
      lastScanAt: sources.lastScanAt[source.id],
      autoScanInterval: service.autoScanIntervalFor(source),
      scanTimeout: service.scanTimeoutFor(source),
      expectedCount: service.scanLimitFor(source),
      weights: weights,
      history: sources.healthHistory[source.id],
      now: now,
      hasTracks: fact != null,
      playable: fact?.playable ?? SourceHealthFacts.unknown.playable,
      artwork: fact?.artwork ?? SourceHealthFacts.unknown.artwork,
      metadata: fact?.metadata ?? SourceHealthFacts.unknown.metadata,
      activity: fact?.activity ?? SourceHealthFacts.unknown.activity,
    );
  }

  return Map.unmodifiable({
    for (final source in sources.sources) source.id: reportFor(source),
  });
});
