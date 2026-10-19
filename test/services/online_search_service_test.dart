import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_repository.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_runtime.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

import 'fake_persistence.dart';

void main() {
  test(
    'on-demand search overrides the query and keeps scan timestamps',
    () async {
      final runtime = _SearchRuntime();
      final config = const MusicSourceConfig(
        id: 'plugin_demo',
        name: 'Demo',
        kind: MusicSourceKind.plugin,
        settings: {'pluginFile': 'demo.js', 'query': 'old'},
      );
      final adapter = MusicPluginSourceAdapter(
        config: config,
        runtime: runtime,
      );
      final store = MusicSourceStore(FakePersistenceService());
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: store,
        pluginRepository: _FakePluginRepository(adapter),
      );

      final results = await service.search(
        sources: [
          config,
          config.copyWith(id: 'local', kind: MusicSourceKind.localDirectory),
          config.copyWith(id: 'plugin_off', enabled: false),
        ],
        query: 'hello',
      );

      expect(results, hasLength(1));
      expect(results.single.status, SourceScanStatus.success);
      expect(results.single.songs.single.title, 'Song hello');
      expect(runtime.lastQuery, 'hello');
      expect(store.lastScanAt('plugin_demo'), isNull);
    },
  );
}

class _FakePluginRepository extends MusicPluginRepository {
  final MusicPluginSourceAdapter adapter;

  _FakePluginRepository(this.adapter);

  @override
  bool get supportsPlugins => true;

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  List<MusicSourceField> fieldsFor(MusicSourceConfig config) => const [];

  @override
  Future<MusicPluginSourceAdapter> adapterFor(MusicSourceConfig config) async =>
      adapter;
}

class _SearchRuntime implements MusicPluginRuntime {
  String? lastQuery;

  @override
  MusicPluginMetadata get metadata => const MusicPluginMetadata(
    platform: 'Search Demo',
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
  }) async {
    lastQuery = query;
    return [
      {'id': '1', 'title': 'Song $query', 'artist': 'Demo', 'duration': 4},
    ];
  }

  @override
  Future<Map<String, dynamic>> getMediaSource(
    Map<String, dynamic> item, {
    String quality = 'standard',
  }) async => {'url': 'https://example.com/${item['id']}.mp3'};

  @override
  Future<Map<String, dynamic>?> getLyric(Map<String, dynamic> item) async =>
      null;

  @override
  Future<Map<String, dynamic>?> getMusicInfo(Map<String, dynamic> item) async =>
      null;

  @override
  Future<void> dispose() async {}
}

class _NoopScanner extends CrossPlatformMusicScannerImpl {
  @override
  Future<List<Song>> scanMusicInDirectoriesWithProgress(
    List<String> directoryPaths,
    Function(double) onProgress,
  ) async => const [];
}
