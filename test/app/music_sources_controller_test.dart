import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';

import '../services/fake_persistence.dart';

void main() {
  test('turns a source on and off and keeps its settings', () async {
    final container = ProviderContainer(
      overrides: [
        musicSourceStoreProvider.overrideWithValue(
          MusicSourceStore(FakePersistenceService()),
        ),
      ],
    );
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
}
