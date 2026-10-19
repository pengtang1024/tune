import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_runtime.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

void main() {
  const config = MusicSourceConfig(
    id: 'plugin_demo',
    name: 'Demo Plugin',
    kind: MusicSourceKind.plugin,
    settings: {'query': 'hello'},
  );

  MusicSourceScanRequest request(MusicSourceConfig config) {
    return MusicSourceScanRequest(config: config);
  }

  test('maps plugin search results into playable songs', () async {
    final runtime = FakeRuntime(
      items: [
        {
          'id': 'track-1',
          'title': 'Hello',
          'artist': 'Artist',
          'album': 'Album',
          'duration': 123,
          'artwork': 'https://example.com/a.jpg',
        },
      ],
      media: {
        'track-1': {
          'url': 'https://example.com/a.mp3',
          'headers': {'Referer': 'https://example.com'},
        },
      },
    );
    final adapter = MusicPluginSourceAdapter(config: config, runtime: runtime);

    final result = await adapter.scan(request(config));

    expect(result.status, SourceScanStatus.success);
    expect(result.songs, hasLength(1));
    final song = result.songs.first;
    expect(song.sourceId, 'plugin_demo');
    expect(song.title, 'Hello');
    expect(song.duration, 123000);
    expect(song.streamUrl, 'https://example.com/a.mp3');
    expect(song.artworkUrl, 'https://example.com/a.jpg');
    expect(song.httpHeaders?['Referer'], 'https://example.com');
    expect(song.sourceData?['id'], 'track-1');
  });

  test('fails instead of wiping the cache when no URL resolves', () async {
    final runtime = FakeRuntime(
      items: [
        {'id': 'track-1', 'title': 'Broken'},
      ],
      media: const {},
    );
    final adapter = MusicPluginSourceAdapter(config: config, runtime: runtime);

    final result = await adapter.scan(request(config));

    expect(result.status, SourceScanStatus.failed);
    expect(result.songs, isEmpty);
    expect(result.message, contains('没有可播放地址'));
  });

  test('requires a search query', () async {
    const empty = MusicSourceConfig(
      id: 'plugin_demo',
      name: 'Demo Plugin',
      kind: MusicSourceKind.plugin,
    );
    final adapter = MusicPluginSourceAdapter(
      config: empty,
      runtime: FakeRuntime(items: const [], media: const {}),
    );

    final result = await adapter.scan(request(empty));

    expect(result.status, SourceScanStatus.needsConfiguration);
  });
}

class FakeRuntime implements MusicPluginRuntime {
  final List<Map<String, dynamic>> items;
  final Map<String, Map<String, dynamic>> media;

  FakeRuntime({required this.items, required this.media});

  @override
  MusicPluginMetadata get metadata => const MusicPluginMetadata(
    platform: 'Demo',
    hasSearch: true,
    hasMediaSource: true,
  );

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
  }) async => items;

  @override
  Future<Map<String, dynamic>> getMediaSource(
    Map<String, dynamic> item, {
    String quality = 'standard',
  }) async {
    final value = media[item['id']];
    if (value == null) {
      throw const MusicPluginException('no source');
    }
    return value;
  }

  @override
  Future<Map<String, dynamic>?> getLyric(Map<String, dynamic> item) async =>
      null;

  @override
  Future<Map<String, dynamic>?> getMusicInfo(Map<String, dynamic> item) async =>
      null;

  @override
  Future<void> dispose() async {}
}
