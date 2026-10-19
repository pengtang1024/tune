import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_downloader.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_repository.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_runtime.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('plugin download', () {
    test('rejects a link that is not http', () async {
      final downloader = MusicPluginDownloader(dio: Dio());
      expect(
        () => downloader.download('file:///tmp/plugin.js'),
        throwsA(isA<MusicPluginException>()),
      );
    });

    test('suggests a file name from the link', () {
      expect(
        MusicPluginDownloader.fileNameFor('https://example.com/a/demo.js'),
        'demo.js',
      );
      expect(
        MusicPluginDownloader.fileNameFor('https://example.com/demo'),
        'demo.js',
      );
    });
  });

  group('plugin install from a link', () {
    late Directory temp;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('tune-plugin-url');
    });

    tearDown(() async {
      await temp.delete(recursive: true);
    });

    test('keeps the address so the plugin can be updated', () async {
      final repository = MusicPluginRepository(
        store: MusicPluginStore(baseDirectory: temp),
        downloader: _FakeDownloader('const plugin = 1;'),
        runtimeFactory: () async => _FakeRuntime(),
      );
      addTearDown(repository.dispose);

      final config = await repository.installFromUrl(
        'https://example.com/demo.js',
      );

      expect(config.pluginUrl, 'https://example.com/demo.js');
      expect(config.pluginFile, isNotNull);
    });

    test('replaces the script when the plugin is updated', () async {
      final downloader = _FakeDownloader('const plugin = 1;');
      final repository = MusicPluginRepository(
        store: MusicPluginStore(baseDirectory: temp),
        downloader: downloader,
        runtimeFactory: () async => _FakeRuntime(),
      );
      addTearDown(repository.dispose);

      final config = await repository.installFromUrl(
        'https://example.com/demo.js',
      );
      final store = MusicPluginStore(baseDirectory: temp);
      expect(await store.read(config), 'const plugin = 1;');

      downloader.script = 'const plugin = 2;';
      final update = await repository.update(config);

      expect(update.changed, isTrue);
      expect(await store.read(config), 'const plugin = 2;');
    });

    test('reports that nothing changed when the script is the same', () async {
      final downloader = _FakeDownloader('const plugin = 1;');
      final repository = MusicPluginRepository(
        store: MusicPluginStore(baseDirectory: temp),
        downloader: downloader,
        runtimeFactory: () async => _FakeRuntime(),
      );
      addTearDown(repository.dispose);

      final config = await repository.installFromUrl(
        'https://example.com/demo.js',
      );
      final update = await repository.update(config);

      expect(update.changed, isFalse);
    });

    test('refuses to update a plugin that has no address', () async {
      final repository = MusicPluginRepository(
        store: MusicPluginStore(baseDirectory: temp),
        downloader: _FakeDownloader('const plugin = 1;'),
        runtimeFactory: () async => _FakeRuntime(),
      );
      addTearDown(repository.dispose);

      final config = await repository.install(
        originalName: 'demo.js',
        script: 'const plugin = 1;',
      );

      expect(config.pluginUrl, isNull);
      await expectLater(
        repository.update(config),
        throwsA(isA<MusicPluginException>()),
      );
    });
  });
}

/// A downloader that answers with a fixed script.
class _FakeDownloader extends MusicPluginDownloader {
  String script;

  _FakeDownloader(this.script) : super(dio: Dio());

  @override
  Future<String> download(String url) async => script;
}

/// A runtime that only reports what the repository needs.
class _FakeRuntime implements MusicPluginRuntime {
  @override
  MusicPluginMetadata get metadata =>
      const MusicPluginMetadata(platform: 'Demo', hasSearch: true);

  @override
  bool get isUsable => true;

  @override
  Future<void> load(
    String script, {
    Map<String, String> userVariables = const {},
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> search(
    String query, {
    int page = 1,
  }) async => const [];

  @override
  Future<Map<String, dynamic>> getMediaSource(
    Map<String, dynamic> item, {
    String quality = 'standard',
  }) async => const {'url': 'https://example.com/a.mp3'};

  @override
  Future<Map<String, dynamic>?> getLyric(Map<String, dynamic> item) async =>
      null;

  @override
  Future<Map<String, dynamic>?> getMusicInfo(Map<String, dynamic> item) async =>
      null;

  @override
  Future<void> dispose() async {}
}
