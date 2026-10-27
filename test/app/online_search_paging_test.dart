import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/search/application/online_search_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';

import '../services/fake_persistence.dart';

/// The search panel asks a pageable source for the next window and appends
/// it to the list instead of replacing what is already shown.
void main() {
  test('loading more appends the next window to the results', () async {
    final service = _PagingService();
    final container = ProviderContainer(
      overrides: [
        musicSourcesControllerProvider.overrideWith(
          () => _FakeSourcesController(),
        ),
        musicSourceServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await container.read(musicSourcesControllerProvider.future);
    await container.read(onlineSearchControllerProvider.future);
    final controller = container.read(onlineSearchControllerProvider.notifier);
    await controller.search('jazz');

    expect(controller.state.requireValue.totalSongs, 1);

    await controller.loadMore('openverse');

    final state = controller.state.requireValue;
    expect(state.totalSongs, 2);
    expect(state.results['openverse']!.songs.map((song) => song.title), [
      'Track 0',
      'Track 1',
    ]);
    expect(service.offsets, [0, 1]);
  });

  test('a source without pages reports that there is nothing more', () async {
    final service = _PagingService(adapter: _NotPagingAdapter());
    final container = ProviderContainer(
      overrides: [
        musicSourcesControllerProvider.overrideWith(
          () => _FakeSourcesController(),
        ),
        musicSourceServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await container.read(musicSourcesControllerProvider.future);
    await container.read(onlineSearchControllerProvider.future);
    final controller = container.read(onlineSearchControllerProvider.notifier);
    await controller.search('jazz');
    await controller.loadMore('openverse');

    final state = controller.state.requireValue;
    expect(state.totalSongs, 1);
    expect(state.message, isNotNull);
  });
}

class _FakeSourcesController extends MusicSourcesController {
  @override
  Future<MusicSourcesState> build() async {
    return const MusicSourcesState(
      sources: [
        MusicSourceConfig(
          id: 'openverse',
          type: 'openverse',
          name: 'Openverse',
          kind: MusicSourceKind.openCatalog,
        ),
      ],
    );
  }
}

/// A service that answers every search with one more track.
class _PagingService extends MusicSourceService {
  _PagingService({MusicSourceAdapter? adapter})
    : super(
        scanner: _EmptyScanner(),
        store: MusicSourceStore(FakePersistenceService()),
        adapters: adapter == null ? null : {'openverse': adapter},
      );

  final offsets = <int>[];

  @override
  Future<List<SourceScanResult>> search({
    required List<MusicSourceConfig> sources,
    required String query,
    Map<String, int> offsets = const {},
    Map<String, String> cursors = const {},
    void Function(String sourceId, double progress)? onProgress,
  }) async {
    final offset = offsets['openverse'] ?? 0;
    this.offsets.add(offset);
    return [
      SourceScanResult(
        sourceId: 'openverse',
        status: SourceScanStatus.success,
        songs: [
          Song(
            id: offset + 1,
            title: 'Track $offset',
            artist: 'Artist',
            uri: 'tune://openverse/$offset',
            sourceId: 'openverse',
            externalId: '$offset',
            streamUrl: 'https://example.com/$offset.mp3',
          ),
        ],
      ),
    ];
  }
}

class _NotPagingAdapter extends _FakeAdapter {
  @override
  bool get supportsPaging => false;

  @override
  String get sourceType => 'openverse';
}

class _FakeAdapter extends _BaseAdapter {}

class _BaseAdapter extends MusicSourceAdapter {
  @override
  String get sourceType => 'openverse';

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  String get configurationHint => '';

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    return SourceScanResult(
      sourceId: request.config.id,
      status: SourceScanStatus.success,
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
