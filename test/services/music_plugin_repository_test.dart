import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_repository.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_store.dart';
import 'package:tune/domain/models/source_scan_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final quickJsAvailable =
      Platform.environment['LIBQUICKJSC_TEST_PATH'] != null ||
      File('libquickjs_c_bridge_plugin.so').existsSync();

  test(
    'installs a plugin, scans it and removes its files',
    () async {
      final temp = await Directory.systemTemp.createTemp('tune-plugin-test');
      addTearDown(() => temp.delete(recursive: true));

      final repository = MusicPluginRepository(
        store: MusicPluginStore(baseDirectory: temp),
      );
      addTearDown(repository.dispose);

      final installed = await repository.install(
        originalName: 'demo.js',
        script: '''
          module.exports = {
            platform: 'Repository Demo',
            version: '2.0.0',
            description: 'End to end test plugin',
            search: async function (query) {
              return {
                isEnd: true,
                data: [{
                  id: 'demo-1',
                  title: 'Song ' + query,
                  artist: 'Demo',
                  album: 'Album',
                  duration: 9,
                }],
              };
            },
            getMediaSource: async function (item) {
              return {
                url: 'https://example.com/' + item.id + '.mp3',
                headers: { Referer: 'https://example.com' },
              };
            },
          };
        ''',
      );

      expect(installed.kind.name, 'plugin');
      expect(installed.name, 'Repository Demo');
      expect(installed.enabled, isFalse);
      expect(installed.pluginFile, isNotNull);

      final configured = installed.copyWith(
        settings: {...installed.settings, 'query': 'hello'},
      );
      final adapter = await repository.adapterFor(configured);
      final result = await adapter.scan(
        MusicSourceScanRequest(config: configured),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs.single.title, 'Song hello');
      expect(result.songs.single.streamUrl, 'https://example.com/demo-1.mp3');
      expect(
        result.songs.single.httpHeaders?['Referer'],
        'https://example.com',
      );

      final file = File('${temp.path}/music_plugins/${installed.pluginFile}');
      expect(await file.exists(), isTrue);

      await repository.remove(configured);
      final store = MusicPluginStore(baseDirectory: temp);
      final names = await store.listFileNames();
      expect(names, isEmpty);
    },
    skip: quickJsAvailable
        ? false
        : 'QuickJS native library is not available outside a built app.',
  );
}
