import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

import 'fake_persistence.dart';

/// One scan can read more than the first window: the pages it reads are
/// joined into one result, and the offset moves with each page.
void main() {
  test('a scan reads the number of pages the source asks for', () async {
    final adapter = _PagingAdapter();
    final service = MusicSourceService(
      scanner: _EmptyScanner(),
      store: MusicSourceStore(FakePersistenceService()),
      adapters: {'demo': adapter},
    );

    final result = (await service.scanAll(
      sources: const [
        MusicSourceConfig(
          id: 'demo',
          type: 'demo',
          name: 'Demo',
          kind: MusicSourceKind.openCatalog,
          settings: {'pages': '3'},
        ),
      ],
      localPaths: const [],
    )).single;

    expect(result.status, SourceScanStatus.success);
    expect(result.songs.map((song) => song.uri), [
      'tune://demo/0',
      'tune://demo/1',
      'tune://demo/2',
    ]);
    expect(adapter.offsets, [0, 1, 2]);
  });

  test('a source without pages is read once even when pages is set', () async {
    final adapter = _PagingAdapter(supportsPaging: false);
    final service = MusicSourceService(
      scanner: _EmptyScanner(),
      store: MusicSourceStore(FakePersistenceService()),
      adapters: {'demo': adapter},
    );

    final result = (await service.scanAll(
      sources: const [
        MusicSourceConfig(
          id: 'demo',
          type: 'demo',
          name: 'Demo',
          kind: MusicSourceKind.openCatalog,
          settings: {'pages': '3'},
        ),
      ],
      localPaths: const [],
    )).single;

    expect(result.songs, hasLength(1));
    expect(adapter.offsets, [0]);
  });
}

class _PagingAdapter extends MusicSourceAdapter {
  _PagingAdapter({this.supportsPaging = true});

  @override
  final bool supportsPaging;

  final offsets = <int>[];

  @override
  String get sourceType => 'demo';

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  String get configurationHint => '';

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    offsets.add(request.offset);
    return SourceScanResult(
      sourceId: request.config.id,
      status: SourceScanStatus.success,
      songs: [
        Song(
          id: request.offset + 1,
          title: 'Track ${request.offset}',
          uri: 'tune://demo/${request.offset}',
          sourceId: 'demo',
          externalId: '${request.offset}',
        ),
      ],
    );
  }
}

class _EmptyScanner extends CrossPlatformMusicScannerImpl {
  @override
  Future<List<Song>> scanMusicInDirectoriesWithProgress(
    List<String> directoryPaths,
    Function(double) onProgress,
  ) async => const [];
}
