import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/sources/domain/source_health.dart';
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
    expect(noScan.score, 63);
    expect(noScan.healthy, isTrue);

    final healthy = SourceHealth.report(
      isLocal: false,
      enabled: true,
      supported: true,
      configured: true,
      summary: success,
      lastScanAt: DateTime.now(),
      autoScanInterval: interval,
      scanTimeout: timeout,
    );
    expect(healthy.score, greaterThanOrEqualTo(80));
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
      coverage: 0,
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
    expect(report.coverage, 50);
  });

  test('stability, coverage and activity move the score', () {
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
      coverage: 1,
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
      coverage: 1,
      activity: 1,
    );

    expect(withHistory.stability, 50);
    expect(withHistory.score, lessThanOrEqualTo(base.score));
    expect(withHistory.coverage, 100);
    expect(withHistory.activity, 100);
  });
}
