import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_repository.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';

import '../services/fake_persistence.dart';

void main() {
  test('imports, configures and removes a plugin source', () async {
    final repository = FakePluginRepository();
    final container = ProviderContainer(
      overrides: [
        musicSourceStoreProvider.overrideWithValue(
          MusicSourceStore(FakePersistenceService()),
        ),
        musicPluginRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(musicSourcesControllerProvider.future);
    final controller = container.read(musicSourcesControllerProvider.notifier);

    final config = await controller.installPlugin(
      originalName: 'demo.js',
      script: 'module.exports = {}',
    );
    var state = container.read(musicSourcesControllerProvider).requireValue;
    expect(state.byId(config.id)?.enabled, isFalse);
    expect(state.byId(config.id)?.isPlugin, isTrue);

    await controller.updateSettings(config.id, {'query': 'hello'});
    await controller.setEnabled(config.id, true);
    state = container.read(musicSourcesControllerProvider).requireValue;
    expect(state.byId(config.id)?.setting('query'), 'hello');
    expect(state.byId(config.id)?.enabled, isTrue);

    await controller.removePlugin(config.id);
    state = container.read(musicSourcesControllerProvider).requireValue;
    expect(state.byId(config.id), isNull);
    expect(repository.removed, isTrue);
  });
}

class FakePluginRepository extends MusicPluginRepository {
  bool removed = false;

  @override
  bool get supportsPlugins => true;

  @override
  Future<MusicSourceConfig> install({
    required String originalName,
    required String script,
  }) async {
    return const MusicSourceConfig(
      id: 'plugin_demo',
      name: 'Demo Plugin',
      kind: MusicSourceKind.plugin,
      enabled: false,
      settings: {'pluginFile': 'plugin_demo.js', 'query': ''},
    );
  }

  @override
  Future<void> remove(MusicSourceConfig config) async {
    removed = true;
  }
}
