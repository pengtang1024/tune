import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

import 'fake_persistence.dart';

/// A search on demand asks every enabled source for the keyword the reader
/// typed, and it leaves the scan timestamps alone.
void main() {
  test(
    'on-demand search overrides the query and keeps scan timestamps',
    () async {
      final adapter = _RecordingAdapter();
      const config = MusicSourceConfig(
        id: 'demo:1',
        type: 'demo',
        name: 'Demo',
        kind: MusicSourceKind.custom,
        settings: {'query': 'old'},
      );
      final store = MusicSourceStore(FakePersistenceService());
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: store,
        adapters: {'demo': adapter},
      );

      final results = await service.search(
        sources: [
          config,
          config.copyWith(
            id: 'local',
            type: 'local',
            kind: MusicSourceKind.localDirectory,
          ),
          config.copyWith(id: 'demo_off', enabled: false),
        ],
        query: 'hello',
      );

      expect(results, hasLength(1));
      expect(results.single.status, SourceScanStatus.success);
      expect(results.single.sourceId, 'demo:1');
      expect(adapter.lastQuery, 'hello');
      expect(store.lastScanAt('demo:1'), isNull);
    },
  );
}

/// An adapter that remembers what it was asked for.
class _RecordingAdapter extends MusicSourceAdapter {
  String? lastQuery;
  String? lastSourceId;

  @override
  String get sourceType => 'demo';

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  String get configurationHint => '';

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    lastQuery = request.config.setting('query');
    lastSourceId = request.config.id;
    return SourceScanResult(
      sourceId: request.config.id,
      status: SourceScanStatus.success,
      songs: [
        Song(id: 1, title: 'Song $lastQuery', artist: 'Someone', uri: 'demo://1'),
      ],
    );
  }
}

/// A scanner that never scans anything.
class _NoopScanner implements CrossPlatformMusicScanner {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
