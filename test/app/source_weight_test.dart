import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/sources/domain/source_health.dart';
import 'package:tune/features/sources/domain/source_health_facts.dart';
import 'package:tune/features/sources/domain/source_order.dart';
import 'package:tune/domain/models/source_health_weights.dart';
import 'package:tune/features/sources/domain/source_scan_health.dart';
import 'package:tune/features/sources/domain/source_weights.dart';

void main() {
  const local = MusicSourceConfig(
    id: 'local',
    type: 'local',
    name: 'Local',
    kind: MusicSourceKind.localDirectory,
    builtIn: true,
  );
  const featured = MusicSourceConfig(
    id: 'openverse',
    type: 'openverse',
    name: 'Openverse',
    kind: MusicSourceKind.openCatalog,
    builtIn: true,
  );
  const more = MusicSourceConfig(
    id: 'itunes',
    type: 'itunes',
    name: 'iTunes',
    kind: MusicSourceKind.openCatalog,
    builtIn: true,
  );
  const added = MusicSourceConfig(
    id: 'openverse-1',
    type: 'openverse',
    name: 'Mine',
    kind: MusicSourceKind.openCatalog,
  );

  test('a weight survives a JSON round trip', () {
    final restored = MusicSourceConfig.fromJson(
      featured.copyWith(weight: 640).toJson(),
    );

    expect(restored.weight, 640);
  });

  test('a configuration from before the weight has none', () {
    final restored = MusicSourceConfig.fromJson({
      'id': 'openverse',
      'type': 'openverse',
      'name': 'Openverse',
      'kind': 'openCatalog',
    });

    expect(restored.weight, isNull);
  });

  test('the local source is pinned and the others get their group default', () {
    expect(SourceWeights.of(local, isFeatured: false), SourceWeights.local);
    expect(
      SourceWeights.of(featured, isFeatured: true),
      SourceWeights.featured,
    );
    expect(SourceWeights.of(more, isFeatured: false), SourceWeights.more);
    expect(SourceWeights.of(added, isFeatured: false), SourceWeights.added);
  });

  test('the threshold decides which group a weight belongs to', () {
    expect(SourceWeights.inMore(SourceWeights.mainThreshold - 1), isTrue);
    expect(SourceWeights.inMore(SourceWeights.mainThreshold), isFalse);
  });

  test('health gates an unusable source out of the main list', () {
    final success = SourceScanSummary(
      sourceId: 'openverse',
      status: SourceScanStatus.success,
      songCount: 3,
      scannedAt: DateTime.now(),
      elapsed: const Duration(seconds: 1),
    );
    final failed = SourceScanSummary(
      sourceId: 'openverse',
      status: SourceScanStatus.failed,
      songCount: 0,
      scannedAt: DateTime(2026),
      elapsed: const Duration(seconds: 40),
    );
    final interval = const Duration(hours: 6);
    final timeout = const Duration(seconds: 45);

    final noScan = SourceHealth.report(
      isLocal: false,
      enabled: true,
      supported: true,
      configured: true,
      summary: null,
      lastScanAt: null,
      autoScanInterval: interval,
      scanTimeout: timeout,
    );
    expect(noScan.score, 42);
    expect(noScan.healthy, isFalse);

    final healthy = SourceHealth.report(
      isLocal: false,
      enabled: true,
      supported: true,
      configured: true,
      summary: success,
      lastScanAt: DateTime.now(),
      autoScanInterval: interval,
      scanTimeout: timeout,
      hasTracks: true,
      expectedCount: 3,
      playable: 1,
      artwork: 1,
      metadata: 1,
      activity: 1,
    );
    expect(healthy.score, greaterThanOrEqualTo(75));
    expect(healthy.healthy, isTrue);

    final broken = SourceHealth.report(
      isLocal: false,
      enabled: true,
      supported: true,
      configured: true,
      summary: failed,
      lastScanAt: DateTime.now(),
      autoScanInterval: interval,
      scanTimeout: timeout,
    );
    expect(broken.score, lessThan(SourceHealth.threshold));

    expect(
      SourceHealth.report(
        isLocal: false,
        enabled: false,
        supported: true,
        configured: true,
        summary: success,
        lastScanAt: DateTime.now(),
        autoScanInterval: interval,
        scanTimeout: timeout,
      ).score,
      0,
    );
    expect(
      SourceHealth.report(
        isLocal: false,
        enabled: true,
        supported: true,
        configured: false,
        summary: null,
        lastScanAt: null,
        autoScanInterval: interval,
        scanTimeout: timeout,
      ).score,
      lessThan(SourceHealth.threshold),
    );
  });

  test('freshness, output and speed move the score', () {
    final interval = const Duration(hours: 6);
    final timeout = const Duration(seconds: 45);
    final summary = SourceScanSummary(
      sourceId: 'openverse',
      status: SourceScanStatus.success,
      songCount: 25,
      scannedAt: DateTime.now(),
      elapsed: const Duration(seconds: 1),
    );

    final freshScan = SourceHealth.report(
      isLocal: false,
      enabled: true,
      supported: true,
      configured: true,
      summary: summary,
      lastScanAt: DateTime.now(),
      autoScanInterval: interval,
      scanTimeout: timeout,
      hasTracks: true,
      playable: 1,
      artwork: 1,
      metadata: 1,
      activity: 1,
    );
    final freshMemory = SourceHealth.report(
      isLocal: false,
      enabled: true,
      supported: true,
      configured: true,
      summary: null,
      lastScanAt: DateTime.now(),
      autoScanInterval: interval,
      scanTimeout: timeout,
      hasTracks: true,
      playable: 1,
      artwork: 1,
      metadata: 1,
      activity: 1,
    );
    final staleMemory = SourceHealth.report(
      isLocal: false,
      enabled: true,
      supported: true,
      configured: true,
      summary: null,
      lastScanAt: DateTime.now().subtract(const Duration(days: 3)),
      autoScanInterval: interval,
      scanTimeout: timeout,
      hasTracks: true,
      playable: 1,
      artwork: 1,
      metadata: 1,
      activity: 1,
    );

    expect(freshScan.score, greaterThan(80));
    expect(freshScan.output, 100);
    expect(freshScan.speed, 100);
    expect(freshMemory.freshness, 100);
    expect(staleMemory.freshness, 0);
    expect(staleMemory.score, lessThan(freshMemory.score));
  });

  test('the dimension weights are normalized', () {
    final weights = SourceHealthWeights.defaults.copyWith(
      availability: 100,
      configuration: 0,
      scan: 0,
      freshness: 0,
      output: 0,
      speed: 0,
      reliability: 0,
      stability: 0,
      playable: 0,
      artwork: 0,
      metadata: 0,
      activity: 0,
    );
    final report = SourceHealth.report(
      isLocal: false,
      enabled: true,
      supported: true,
      configured: true,
      summary: null,
      lastScanAt: null,
      autoScanInterval: const Duration(hours: 6),
      scanTimeout: const Duration(seconds: 45),
      weights: weights,
    );

    expect(report.score, 100);
    expect(report.availability, 100);
    expect(report.artwork, 25);
  });

  test('stability, coverage facts and activity move the score', () {
    final history = SourceScanHealthHistory(
      records: [
        SourceScanHealthRecord(
          status: SourceScanStatus.success,
          songCount: 3,
          elapsed: const Duration(seconds: 1),
          at: DateTime.now(),
        ),
        SourceScanHealthRecord(
          status: SourceScanStatus.failed,
          songCount: 0,
          elapsed: const Duration(seconds: 40),
          at: DateTime.now(),
        ),
      ],
    );
    final base = SourceHealth.report(
      isLocal: false,
      enabled: true,
      supported: true,
      configured: true,
      summary: null,
      lastScanAt: null,
      autoScanInterval: const Duration(hours: 6),
      scanTimeout: const Duration(seconds: 45),
      playable: 1,
      artwork: 1,
      metadata: 1,
      activity: 1,
    );
    final withHistory = SourceHealth.report(
      isLocal: false,
      enabled: true,
      supported: true,
      configured: true,
      summary: null,
      lastScanAt: null,
      autoScanInterval: const Duration(hours: 6),
      scanTimeout: const Duration(seconds: 45),
      history: history,
      playable: 1,
      artwork: 1,
      metadata: 1,
      activity: 1,
    );

    expect(withHistory.stability, 50);
    // A known 50% history is better than no history at all.
    expect(withHistory.score, greaterThan(base.score));
    expect(withHistory.playable, 100);
    expect(withHistory.artwork, 100);
    expect(withHistory.metadata, 100);
    expect(withHistory.activity, 100);
  });

  test('a source without covers scores below one with covers', () {
    final summary = SourceScanSummary(
      sourceId: 'openverse',
      status: SourceScanStatus.success,
      songCount: 25,
      scannedAt: DateTime.now(),
      elapsed: const Duration(seconds: 1),
    );
    SourceHealthReport report({required double artwork}) {
      return SourceHealth.report(
        isLocal: false,
        enabled: true,
        supported: true,
        configured: true,
        summary: summary,
        lastScanAt: DateTime.now(),
        autoScanInterval: const Duration(hours: 6),
        scanTimeout: const Duration(seconds: 45),
        hasTracks: true,
        playable: 1,
        artwork: artwork,
        metadata: 1,
        activity: 1,
      );
    }

    final covered = report(artwork: 1);
    final bare = report(artwork: 0);

    expect(covered.artwork, 100);
    expect(bare.artwork, 0);
    expect(covered.score - bare.score, greaterThanOrEqualTo(7));
    expect(bare.score, lessThanOrEqualTo(55));
    expect(bare.healthy, isFalse);
  });

  test('an empty source is not capped for missing covers', () {
    final summary = SourceScanSummary(
      sourceId: 'openverse',
      status: SourceScanStatus.success,
      songCount: 3,
      scannedAt: DateTime.now(),
      elapsed: const Duration(seconds: 1),
    );
    final weights = SourceHealthWeights.defaults.copyWith(
      freshness: 0,
      output: 0,
      speed: 0,
      reliability: 0,
      stability: 0,
      playable: 0,
      artwork: 0,
      metadata: 0,
      activity: 0,
    );
    final report = SourceHealth.report(
      isLocal: false,
      enabled: true,
      supported: true,
      configured: true,
      summary: summary,
      lastScanAt: summary.scannedAt,
      autoScanInterval: const Duration(hours: 6),
      scanTimeout: const Duration(seconds: 45),
      weights: weights,
      hasTracks: false,
      playable: 0,
      artwork: 0,
      metadata: 0,
      activity: 0,
    );

    expect(report.score, greaterThan(55));
  });

  test('an old coverage weight is split into the three facts', () {
    final restored = SourceHealthWeights.fromJson({
      'availability': 10,
      'configuration': 15,
      'scan': 15,
      'freshness': 10,
      'output': 10,
      'speed': 5,
      'reliability': 10,
      'stability': 10,
      'coverage': 20,
      'activity': 5,
    });

    expect(restored.playable, 12);
    expect(restored.artwork, 4);
    expect(restored.metadata, 4);
  });

  test('new coverage weights win over an old coverage value', () {
    final restored = SourceHealthWeights.fromJson({
      'coverage': 20,
      'playable': 3,
      'artwork': 7,
      'metadata': 1,
    });

    expect(restored.playable, 3);
    expect(restored.artwork, 7);
    expect(restored.metadata, 1);
  });

  test('metadata counts artist, album and year', () {
    const songs = [
      Song(
        id: 1,
        uri: 'tune://openverse/one',
        sourceId: 'openverse',
        externalId: 'one',
        artist: 'Artist',
        album: 'Album',
        year: 2001,
      ),
      Song(
        id: 2,
        uri: 'tune://openverse/two',
        sourceId: 'openverse',
        externalId: 'two',
        artist: 'Artist',
      ),
    ];

    final facts = sourceHealthFactsOf(songs);

    // One fully tagged track (1.0) and one with only an artist (0.6).
    expect(facts['openverse']!.metadata, closeTo(0.8, 1e-9));
  });

  test('a recent success outweighs an old failure', () {
    final now = DateTime(2026, 10, 24);
    final history = SourceScanHealthHistory(
      records: [
        SourceScanHealthRecord(
          status: SourceScanStatus.failed,
          songCount: 0,
          elapsed: Duration.zero,
          at: now.subtract(const Duration(days: 90)),
        ),
        SourceScanHealthRecord(
          status: SourceScanStatus.success,
          songCount: 3,
          elapsed: const Duration(seconds: 1),
          at: now,
        ),
      ],
    );

    expect(history.stabilityRate, greaterThan(0.5));
    expect(history.stabilityRate, lessThan(1.0));
  });

  test('source facts are counted in one pass', () {
    const songs = [
      Song(
        id: 1,
        uri: 'tune://openverse/one',
        sourceId: 'openverse',
        externalId: 'one',
        streamUrl: 'https://example.com/one.mp3',
        artworkUrl: 'https://example.com/one.jpg',
        artist: 'Artist',
      ),
      Song(
        id: 2,
        uri: 'tune://openverse/two',
        sourceId: 'openverse',
        externalId: 'two',
        streamUrl: 'https://example.com/two.mp3',
      ),
    ];
    final facts = sourceHealthFactsOf(
      songs,
      favoriteUris: {'tune://openverse/one'},
    );
    final openverse = facts['openverse']!;

    expect(openverse.playable, 1);
    expect(openverse.artwork, 0.5);
    expect(openverse.metadata, 0.3);
    expect(openverse.activity, 0.5);
  });

  test('output is measured against the requested count', () {
    SourceScanSummary summary(int count) => SourceScanSummary(
      sourceId: 'openverse',
      status: SourceScanStatus.success,
      songCount: count,
      scannedAt: DateTime.now(),
      elapsed: const Duration(seconds: 1),
    );
    int outputOf(int count, {int? expected}) {
      return SourceHealth.report(
        isLocal: false,
        enabled: true,
        supported: true,
        configured: true,
        summary: summary(count),
        lastScanAt: DateTime.now(),
        autoScanInterval: const Duration(hours: 6),
        scanTimeout: const Duration(seconds: 45),
        expectedCount: expected,
      ).output;
    }

    expect(outputOf(10, expected: 20), 50);
    expect(outputOf(20, expected: 20), 100);
    expect(outputOf(10), 66);
  });

  test('a skipped scan keeps output neutral', () {
    final summary = SourceScanSummary(
      sourceId: 'openverse',
      status: SourceScanStatus.skipped,
      songCount: 0,
      scannedAt: DateTime.now(),
      elapsed: Duration.zero,
    );
    final report = SourceHealth.report(
      isLocal: false,
      enabled: true,
      supported: true,
      configured: true,
      summary: summary,
      lastScanAt: summary.scannedAt,
      autoScanInterval: const Duration(hours: 6),
      scanTimeout: const Duration(seconds: 45),
      expectedCount: 20,
    );

    expect(report.output, 50);
  });

  test('activity is unknown before the first heart', () {
    const songs = [
      Song(
        id: 1,
        uri: 'tune://openverse/one',
        sourceId: 'openverse',
        externalId: 'one',
        streamUrl: 'https://example.com/one.mp3',
      ),
    ];

    final facts = sourceHealthFactsOf(songs);

    expect(facts['openverse']!.activity, 0.25);
  });

  test('band order keeps the weight order inside a band', () {
    SourceHealthReport report(int score) => SourceHealthReport(
      availability: 100,
      configuration: 100,
      scan: 100,
      freshness: 100,
      output: 100,
      speed: 100,
      reliability: 100,
      stability: 100,
      playable: 100,
      artwork: 100,
      metadata: 100,
      activity: 100,
      score: score,
      healthy: score >= SourceHealth.threshold,
    );
    const heavier = MusicSourceConfig(
      id: 'heavier',
      type: 'openverse',
      name: 'Heavier',
      kind: MusicSourceKind.openCatalog,
      builtIn: true,
    );
    const lighter = MusicSourceConfig(
      id: 'lighter',
      type: 'openverse',
      name: 'Lighter',
      kind: MusicSourceKind.openCatalog,
      builtIn: true,
    );

    final ordered = orderSourcesByBand(
      [heavier, lighter],
      {'heavier': report(65), 'lighter': report(90)},
    );
    expect(ordered.map((source) => source.id), ['lighter', 'heavier']);

    final sameBand = orderSourcesByBand(
      [heavier, lighter],
      {'heavier': report(75), 'lighter': report(80)},
    );
    expect(sameBand.map((source) => source.id), ['heavier', 'lighter']);
  });

  test('favorites outside the library keep activity unknown', () {
    const songs = [
      Song(
        id: 1,
        uri: 'tune://openverse/one',
        sourceId: 'openverse',
        externalId: 'one',
        streamUrl: 'https://example.com/one.mp3',
      ),
    ];

    final facts = sourceHealthFactsOf(
      songs,
      favoriteUris: {'/music/not-in-the-library.mp3'},
    );

    expect(facts['openverse']!.activity, 0.25);
  });

  test('a source with tracks but no playable track is capped', () {
    final summary = SourceScanSummary(
      sourceId: 'openverse',
      status: SourceScanStatus.success,
      songCount: 20,
      scannedAt: DateTime.now(),
      elapsed: const Duration(seconds: 1),
    );
    final report = SourceHealth.report(
      isLocal: false,
      enabled: true,
      supported: true,
      configured: true,
      summary: summary,
      lastScanAt: summary.scannedAt,
      autoScanInterval: const Duration(hours: 6),
      scanTimeout: const Duration(seconds: 45),
      hasTracks: true,
      expectedCount: 20,
      playable: 0,
      artwork: 1,
      metadata: 1,
      activity: 1,
    );

    expect(report.playable, 0);
    expect(report.score, lessThanOrEqualTo(55));
    expect(report.healthy, isFalse);
  });

  test('setting the artwork weight to zero removes the cover cap', () {
    final summary = SourceScanSummary(
      sourceId: 'openverse',
      status: SourceScanStatus.success,
      songCount: 20,
      scannedAt: DateTime.now(),
      elapsed: const Duration(seconds: 1),
    );
    final report = SourceHealth.report(
      isLocal: false,
      enabled: true,
      supported: true,
      configured: true,
      summary: summary,
      lastScanAt: summary.scannedAt,
      autoScanInterval: const Duration(hours: 6),
      scanTimeout: const Duration(seconds: 45),
      weights: SourceHealthWeights.defaults.copyWith(artwork: 0),
      hasTracks: true,
      expectedCount: 20,
      playable: 1,
      artwork: 0,
      metadata: 1,
      activity: 1,
    );

    expect(report.artwork, 0);
    expect(report.score, greaterThan(55));
  });

  test('health bands separate the main list', () {
    expect(SourceHealth.bandOf(100), 2);
    expect(SourceHealth.bandOf(85), 2);
    expect(SourceHealth.bandOf(84), 1);
    expect(SourceHealth.bandOf(70), 1);
    expect(SourceHealth.bandOf(69), 0);
  });
}
