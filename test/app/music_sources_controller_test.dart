import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/sources/domain/source_weights.dart';

import '../services/fake_persistence.dart';

void main() {
  ProviderContainer containerFor(FakePersistenceService persistence) {
    return ProviderContainer(
      overrides: [
        musicSourceStoreProvider.overrideWithValue(
          MusicSourceStore(persistence),
        ),
      ],
    );
  }

  test('turns a source on and off and keeps its settings', () async {
    final container = containerFor(FakePersistenceService());
    addTearDown(container.dispose);

    await container.read(musicSourcesControllerProvider.future);
    final controller = container.read(musicSourcesControllerProvider.notifier);
    final state = container.read(musicSourcesControllerProvider).requireValue;
    final openverse = state.byId('openverse');
    expect(openverse, isNotNull);

    await controller.updateSettings(openverse!.id, {'query': 'ambient'});
    await controller.setEnabled(openverse.id, false);

    final updated = container.read(musicSourcesControllerProvider).requireValue;
    expect(updated.byId(openverse.id)?.setting('query'), 'ambient');
    expect(updated.byId(openverse.id)?.enabled, isFalse);
  });

  test('normalises the weights and pins the local source', () async {
    final container = containerFor(FakePersistenceService());
    addTearDown(container.dispose);

    await container.read(musicSourcesControllerProvider.future);
    final state = container.read(musicSourcesControllerProvider).requireValue;

    expect(state.sources.first.id, 'local');
    expect(state.byId('local')!.weight, SourceWeights.local);
    expect(
      state.byId('openverse')!.weight,
      greaterThanOrEqualTo(SourceWeights.mainThreshold),
    );
    expect(state.byId('itunes')!.weight, lessThan(SourceWeights.mainThreshold));
  });

  test('a source folds into More and comes back', () async {
    final container = containerFor(FakePersistenceService());
    addTearDown(container.dispose);

    await container.read(musicSourcesControllerProvider.future);
    final controller = container.read(musicSourcesControllerProvider.notifier);

    await controller.setSourceInMore('openverse', true);
    var state = container.read(musicSourcesControllerProvider).requireValue;
    expect(
      state.byId('openverse')!.weight,
      lessThan(SourceWeights.mainThreshold),
    );

    await controller.setSourceInMore('openverse', false);
    state = container.read(musicSourcesControllerProvider).requireValue;
    expect(
      state.byId('openverse')!.weight,
      greaterThanOrEqualTo(SourceWeights.mainThreshold),
    );
  });

  test('the local source cannot be moved or folded', () async {
    final container = containerFor(FakePersistenceService());
    addTearDown(container.dispose);

    await container.read(musicSourcesControllerProvider.future);
    final controller = container.read(musicSourcesControllerProvider.notifier);

    await controller.swapSources('local', 'openverse');
    await controller.setSourceInMore('local', true);

    final state = container.read(musicSourcesControllerProvider).requireValue;
    expect(state.sources.first.id, 'local');
    expect(state.byId('local')!.weight, SourceWeights.local);
  });

  test('swapping two sources trades their weights', () async {
    final container = containerFor(FakePersistenceService());
    addTearDown(container.dispose);

    await container.read(musicSourcesControllerProvider.future);
    final controller = container.read(musicSourcesControllerProvider.notifier);
    final state = container.read(musicSourcesControllerProvider).requireValue;
    final first = state.sources[1];
    final second = state.sources[2];

    await controller.swapSources(first.id, second.id);

    final updated = container.read(musicSourcesControllerProvider).requireValue;
    expect(updated.byId(first.id)!.weight, second.weight);
    expect(updated.byId(second.id)!.weight, first.weight);
  });

  test('the weight survives a controller rebuild', () async {
    final persistence = FakePersistenceService();
    final first = containerFor(persistence);
    addTearDown(first.dispose);
    await first.read(musicSourcesControllerProvider.future);
    await first
        .read(musicSourcesControllerProvider.notifier)
        .setSourceInMore('openverse', true);

    final second = containerFor(persistence);
    addTearDown(second.dispose);
    await second.read(musicSourcesControllerProvider.future);
    final state = second.read(musicSourcesControllerProvider).requireValue;
    expect(
      state.byId('openverse')!.weight,
      lessThan(SourceWeights.mainThreshold),
    );
  });

  test('the scan history survives a controller rebuild', () async {
    final persistence = FakePersistenceService();
    final first = containerFor(persistence);
    addTearDown(first.dispose);
    await first.read(musicSourcesControllerProvider.future);
    final controller = first.read(musicSourcesControllerProvider.notifier);

    await controller.recordScanResults([
      SourceScanResult(
        sourceId: 'openverse',
        status: SourceScanStatus.success,
        elapsed: const Duration(seconds: 1),
        scannedAt: DateTime(2026),
      ),
      SourceScanResult(
        sourceId: 'openverse',
        status: SourceScanStatus.failed,
        elapsed: const Duration(seconds: 40),
        scannedAt: DateTime(2026),
      ),
    ]);

    final state = first.read(musicSourcesControllerProvider).requireValue;
    expect(state.healthHistory['openverse']?.records, hasLength(2));

    final second = containerFor(persistence);
    addTearDown(second.dispose);
    await second.read(musicSourcesControllerProvider.future);
    final reloaded = second
        .read(musicSourcesControllerProvider)
        .requireValue
        .healthHistory['openverse'];
    expect(reloaded?.records, hasLength(2));
    expect(reloaded?.stabilityRate, lessThan(1));
  });
}
