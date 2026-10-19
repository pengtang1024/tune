import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_runtime_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final quickJsAvailable =
      Platform.environment['LIBQUICKJSC_TEST_PATH'] != null ||
      File('libquickjs_c_bridge_plugin.so').existsSync();

  test(
    'loads a MusicFree plugin and resolves its media source',
    () async {
      final runtime = await IoMusicPluginRuntime.create();
      addTearDown(runtime.dispose);

      await runtime.load(
        '''
        module.exports = {
          platform: 'Demo Plugin',
          version: '1.2.3',
          description: 'A tiny test plugin',
          userVariables: [
            { key: 'cookie', title: 'Cookie', default: 'abc' },
          ],
          search: async function (query, page, type) {
            return {
              isEnd: true,
              data: [
                {
                  id: 'track-1',
                  title: query + ' song',
                  artist: env.getUserVariables().cookie,
                  album: 'Demo Album',
                  duration: 123,
                  artwork: 'https://example.com/cover.jpg',
                },
              ],
            };
          },
          getMediaSource: async function (item, quality) {
            return { url: 'https://example.com/' + item.id + '.mp3' };
          },
        };
      ''',
        userVariables: {'cookie': 'session-1'},
      );

      expect(runtime.metadata.platform, 'Demo Plugin');
      expect(runtime.metadata.version, '1.2.3');
      expect(runtime.metadata.hasSearch, isTrue);
      expect(runtime.metadata.hasMediaSource, isTrue);
      expect(runtime.metadata.userVariables.single.key, 'cookie');
      expect(runtime.metadata.userVariables.single.title, 'Cookie');

      final items = await runtime.search('hello');
      expect(items, hasLength(1));
      expect(items.first['title'], 'hello song');
      expect(items.first['artist'], 'session-1');
      expect(items.first['duration'], 123);

      final media = await runtime.getMediaSource(items.first);
      expect(media['url'], 'https://example.com/track-1.mp3');
    },
    skip: quickJsAvailable
        ? false
        : 'QuickJS native library is not available outside a built app.',
  );
}
