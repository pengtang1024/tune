import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/providers/cross_platform_music_scanner_provider.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/data/services/providers/song_download_service_provider.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/data/library_storage.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';

import '../services/fake_persistence.dart';
import 'fake_song_download_service.dart';

void main() {
  const localSong = Song(
    id: 1,
    title: 'Local Song',
    artist: 'Local',
    uri: '/music/local.mp3',
  );
  const oldRemoteSong = Song(
    id: 2,
    title: 'Old Remote',
    artist: 'Remote',
    uri: 'tune://openverse/old',
    sourceId: 'openverse',
    externalId: 'old',
    streamUrl: 'https://example.com/old.mp3',
  );
  const newRemoteSong = Song(
    id: 3,
    title: 'New Remote',
    artist: 'Remote',
    uri: 'tune://openverse/new',
    sourceId: 'openverse',
    externalId: 'new',
    streamUrl: 'https://example.com/new.mp3',
  );

  const localSource = MusicSourceConfig(
    id: 'local',
    name: '本地音乐',
    kind: MusicSourceKind.localDirectory,
  );
  const remoteSource = MusicSourceConfig(
    id: 'openverse',
    name: 'Openverse',
    kind: MusicSourceKind.openCatalog,
  );

  late FakeSourceService service;
  late FakeLibraryStorage storage;
  late FakeSongDownloadService downloads;

  setUp(() {
    service = FakeSourceService();
    storage = FakeLibraryStorage([localSong, oldRemoteSong]);
    downloads = FakeSongDownloadService();
  });

  ProviderContainer createContainer({
    required List<MusicSourceConfig> sources,
    required Map<String, SourceScanResult> results,
  }) {
    service.results = results;
    final container = ProviderContainer(
      overrides: [
        libraryStorageProvider.overrideWithValue(storage),
        crossPlatformMusicScannerProvider.overrideWithValue(FakeScanner()),
        musicSourceServiceProvider.overrideWithValue(service),
        songDownloadServiceProvider.overrideWithValue(downloads),
        musicSourcesControllerProvider.overrideWith(
          () => FakeSourcesController(MusicSourcesState(sources: sources)),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('a failed source keeps its cached songs', () async {
    final container = createContainer(
      sources: const [localSource, remoteSource],
      results: {
        'local': SourceScanResult(
          sourceId: 'local',
          status: SourceScanStatus.success,
          songs: [localSong],
        ),
        'openverse': SourceScanResult(
          sourceId: 'openverse',
          status: SourceScanStatus.failed,
          message: '网络连接超时',
        ),
      },
    );

    await container.read(libraryControllerProvider.future);
    await container.read(libraryControllerProvider.notifier).scan(['/music']);

    final state = container.read(libraryControllerProvider).requireValue;
    expect(state.songs.map((song) => song.uri), [
      localSong.uri,
      oldRemoteSong.uri,
    ]);
    expect(state.sourceSummaries['openverse']?.status, SourceScanStatus.failed);
    expect(state.statusMessage, contains('1 个音源失败'));
  });

  test(
    'a skipped source keeps its cached songs and no error is shown',
    () async {
      // The web build has no music folder, so every source is skipped when the
      // last scan is still too recent. The library keeps the songs of that
      // scan, so the player must not report a failure.
      final container = createContainer(
        sources: const [localSource, remoteSource],
        results: {
          'local': SourceScanResult(
            sourceId: 'local',
            status: SourceScanStatus.skipped,
            message: '距上次扫描不足间隔',
          ),
          'openverse': SourceScanResult(
            sourceId: 'openverse',
            status: SourceScanStatus.skipped,
            message: '距上次扫描不足间隔',
          ),
        },
      );

      await container.read(libraryControllerProvider.future);
      await container.read(libraryControllerProvider.notifier).scan(['/music']);

      final state = container.read(libraryControllerProvider).requireValue;
      expect(state.songs.map((song) => song.uri), [
        localSong.uri,
        oldRemoteSong.uri,
      ]);
      expect(state.errorMessage, isNull);
      expect(state.statusMessage, '已保留缓存，距上次扫描不足间隔');
    },
  );

  test('a successful source replaces its previous songs', () async {
    final container = createContainer(
      sources: const [localSource, remoteSource],
      results: {
        'local': SourceScanResult(
          sourceId: 'local',
          status: SourceScanStatus.success,
          songs: [localSong],
        ),
        'openverse': SourceScanResult(
          sourceId: 'openverse',
          status: SourceScanStatus.success,
          songs: [newRemoteSong],
        ),
      },
    );

    await container.read(libraryControllerProvider.future);
    await container.read(libraryControllerProvider.notifier).scan(['/music']);

    final state = container.read(libraryControllerProvider).requireValue;
    expect(state.songs.map((song) => song.uri), [
      localSong.uri,
      newRemoteSong.uri,
    ]);
    expect(state.statusMessage, '已扫描 2 个音源，共 2 首歌曲');
  });

  test('a disabled source is removed from the active library', () async {
    final container = createContainer(
      sources: const [localSource],
      results: {
        'local': SourceScanResult(
          sourceId: 'local',
          status: SourceScanStatus.success,
          songs: [localSong],
        ),
      },
    );

    await container.read(libraryControllerProvider.future);
    await container.read(libraryControllerProvider.notifier).scan(['/music']);

    final state = container.read(libraryControllerProvider).requireValue;
    expect(state.songs.map((song) => song.uri), [localSong.uri]);
    expect(state.sourceSummaries.containsKey('openverse'), isFalse);
  });

  test('a copy and the track of its source are one track', () async {
    // The copy on the disk carries the identity of the track it belongs to,
    // so the library knows the two are the same song.
    const copy = Song(
      id: 2,
      title: 'Old Remote',
      artist: 'Remote',
      uri: 'tune://openverse/old',
      sourceId: 'openverse',
      externalId: 'old',
      localPath: '/music/Remote/Old Remote/Old Remote.mp3',
      size: 4096,
    );
    final container = createContainer(
      sources: const [localSource, remoteSource],
      results: {
        'local': SourceScanResult(
          sourceId: 'local',
          status: SourceScanStatus.success,
          songs: [localSong, copy],
        ),
        'openverse': SourceScanResult(
          sourceId: 'openverse',
          status: SourceScanStatus.success,
          songs: [oldRemoteSong],
        ),
      },
    );

    await container.read(libraryControllerProvider.future);
    await container.read(libraryControllerProvider.notifier).scan(['/music']);

    final state = container.read(libraryControllerProvider).requireValue;
    expect(state.songs.map((song) => song.uri), [
      localSong.uri,
      oldRemoteSong.uri,
    ]);

    final merged = state.songs.firstWhere(
      (song) => song.uri == oldRemoteSong.uri,
    );
    // The track knows both: it comes from a source and it is on this machine.
    expect(merged.hasRemoteSource, isTrue);
    expect(merged.hasLocalFile, isTrue);
    expect(merged.localPath, copy.localPath);
    // What only one side knows is kept.
    expect(merged.streamUrl, oldRemoteSong.streamUrl);
    expect(merged.size, copy.size);
  });

  test('a rescan keeps the first time a track entered the library', () async {
    const firstSeen = Song(
      id: 10,
      title: 'Already Here',
      uri: 'tune://openverse/old',
      sourceId: 'openverse',
      externalId: 'old',
      dateAdded: 1000,
    );
    const rescanned = Song(
      id: 10,
      title: 'Already Here',
      uri: 'tune://openverse/old',
      sourceId: 'openverse',
      externalId: 'old',
      dateAdded: 9000,
    );
    const brandNew = Song(
      id: 11,
      title: 'Brand New',
      uri: 'tune://openverse/new',
      sourceId: 'openverse',
      externalId: 'new',
      dateAdded: 8000,
    );
    storage.songs = [firstSeen];

    final container = createContainer(
      sources: const [localSource, remoteSource],
      results: {
        'local': SourceScanResult(
          sourceId: 'local',
          status: SourceScanStatus.success,
          songs: [],
        ),
        'openverse': SourceScanResult(
          sourceId: 'openverse',
          status: SourceScanStatus.success,
          songs: [rescanned, brandNew],
        ),
      },
    );

    await container.read(libraryControllerProvider.future);
    await container.read(libraryControllerProvider.notifier).scan(['/music']);

    final state = container.read(libraryControllerProvider).requireValue;
    expect(
      state.songs.firstWhere((song) => song.uri == rescanned.uri).dateAdded,
      1000,
    );
    expect(
      state.songs.firstWhere((song) => song.uri == brandNew.uri).dateAdded,
      8000,
    );
  });

  test('the copies of the library are marked before it is read', () async {
    // A copy that was fetched before the app kept markers is marked now, so
    // the scan of the music library finds it as a copy of its track.
    final container = createContainer(
      sources: const [localSource, remoteSource],
      results: {
        'local': SourceScanResult(
          sourceId: 'local',
          status: SourceScanStatus.success,
          songs: [localSong],
        ),
        'openverse': SourceScanResult(
          sourceId: 'openverse',
          status: SourceScanStatus.success,
          songs: [oldRemoteSong],
        ),
      },
    );

    await container.read(libraryControllerProvider.future);
    await container.read(libraryControllerProvider.notifier).scan(['/music']);

    expect(downloads.markedUris, contains(oldRemoteSong.uri));
  });
}

class FakeScanner extends CrossPlatformMusicScannerImpl {
  @override
  Future<List<Song>> scanMusicInDirectoriesWithProgress(
    List<String> directoryPaths,
    Function(double) onProgress,
  ) async {
    return const [];
  }
}

class FakeSourceService extends MusicSourceService {
  FakeSourceService()
    : super(
        scanner: FakeScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

  Map<String, SourceScanResult> results = const {};

  @override
  Future<List<SourceScanResult>> scanAll({
    required List<MusicSourceConfig> sources,
    required List<String> localPaths,
    bool respectAutoScanInterval = false,
    void Function(String sourceId, double progress)? onProgress,
  }) async {
    return [
      for (final source in sources.where((source) => source.enabled))
        results[source.id] ??
            SourceScanResult(
              sourceId: source.id,
              status: SourceScanStatus.skipped,
            ),
    ];
  }
}

class FakeSourcesController extends MusicSourcesController {
  FakeSourcesController(this.seed);

  final MusicSourcesState seed;

  @override
  Future<MusicSourcesState> build() async => seed;
}

class FakeLibraryStorage extends LibraryStorage {
  FakeLibraryStorage(this.songs);

  List<Song> songs;

  @override
  Future<List<Song>> load() async => List.unmodifiable(songs);

  @override
  Future<void> save(List<Song> songs) async {
    this.songs = List.of(songs);
  }

  @override
  Future<void> clear() async {
    songs = [];
  }
}
