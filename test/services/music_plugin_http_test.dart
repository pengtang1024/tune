import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_runtime_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  final quickJsAvailable =
      Platform.environment['LIBQUICKJSC_TEST_PATH'] != null ||
      File('libquickjs_c_bridge_plugin.so').existsSync();

  test(
    'plugin axios can call a local HTTP API',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) {
        request.response
          ..headers.contentType = ContentType.json
          ..write('{"title":"from-server"}')
          ..close();
      });

      final runtime = await IoMusicPluginRuntime.create();
      addTearDown(runtime.dispose);

      await runtime.load('''
        const axios = require('axios');
        module.exports = {
          platform: 'HTTP Demo',
          search: async function (query, page, type) {
            const response = await axios.get(
              'http://127.0.0.1:${server.port}/search',
              { params: { q: query } }
            );
            return {
              isEnd: true,
              data: [{
                id: '1',
                title: response.data.title,
                artist: 'Server',
                duration: 5,
              }],
            };
          },
          getMediaSource: async function () {
            return { url: 'https://example.com/a.mp3' };
          },
        };
      ''');

      final items = await runtime.search('hello');
      expect(items.single['title'], 'from-server');
    },
    skip: quickJsAvailable
        ? false
        : 'QuickJS native library is not available outside a built app.',
  );
}
