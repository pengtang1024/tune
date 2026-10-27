import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/providers/cross_platform_music_scanner_provider.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/data/services/providers/song_download_service_provider.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/data/library_storage.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';

import '../services/fake_persistence.dart';
import 'fake_song_download_service.dart';

void main() {
  const songA = Song(
    id: 1,
    title: 'Alpha',
    artist: 'Artist A',
    duration: 180000,
    uri: '/music/a.mp3',
  );
  const songB = Song(
    id: 2,
    title: 'Beta',
    artist: 'Artist B',
    duration: 120000,
    uri: '/music/b.mp3',
  );
  const songC = Song(
    id: 3,
    title: 'Gamma',
    artist: 'Artist C',
    duration: 90000,
    uri: '/music/c.mp3',
  );

  late FakeLibraryStorage storage;
  late FakeMusicScanner scanner;
  late FakeMusicSourceStore sourceStore;
  late FakeSongDownloadService downloads;
  late ProviderContainer container;

  setUp(() {
    storage = FakeLibraryStorage([songA]);
    scanner = FakeMusicScanner();
    sourceStore = FakeMusicSourceStore();
    downloads = FakeSongDownloadService();
    container = ProviderContainer(
      overrides: [
        libraryStorageProvider.overrideWithValue(storage),
        crossPlatformMusicScannerProvider.overrideWithValue(scanner),
        musicSourceStoreProvider.overrideWithValue(sourceStore),
        songDownloadServiceProvider.overrideWithValue(downloads),
        musicSourcesControllerProvider.overrideWith(
          FakeMusicSourcesController.new,
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test('build loads the persisted library', () async {
    final state = await container.read(libraryControllerProvider.future);

    expect(state.songs.map((song) => song.uri), [songA.uri]);
    expect(state.statusMessage, '1 首歌曲');
  });

  test('scan adds to the library and persists sorted songs', () async {
    await container.read(libraryControllerProvider.future);
    scanner.songs = [songC, songB];

    await container.read(libraryControllerProvider.notifier).scan([
      ' /music ',
      '/music',
    ]);

    final state = container.read(libraryControllerProvider).requireValue;
    expect(scanner.lastPaths, ['/music']);
    expect(state.scanStatus, LibraryScanStatus.completed);
    // The scanned window joins the persisted library instead of replacing it.
    expect(state.songs.map((song) => song.title), ['Alpha', 'Beta', 'Gamma']);
    expect(state.statusMessage, '已扫描 3 首歌曲');
    expect(storage.songs.map((song) => song.title), ['Alpha', 'Beta', 'Gamma']);
    expect(storage.saveCount, 1);
  });

  test('startup auto scan runs once with the configured paths', () async {
    await container.read(libraryControllerProvider.future);
    scanner.songs = [songB];
    final controller = container.read(libraryControllerProvider.notifier);

    await controller.autoScan(['/music']);
    await controller.autoScan(['/other']);

    expect(scanner.scanCount, 1);
    expect(scanner.lastPaths, ['/music']);
    final state = container.read(libraryControllerProvider).requireValue;
    expect(state.songs.map((song) => song.uri), [songA.uri, songB.uri]);
  });

  test('scan marks the source timestamp after saving songs', () async {
    await container.read(libraryControllerProvider.future);
    scanner.songs = [songB];

    await container.read(libraryControllerProvider.notifier).scan(['/music']);

    expect(storage.saveCount, 1);
    expect(sourceStore.marked, ['local']);
  });

  test('failed library save does not mark the source as scanned', () async {
    await container.read(libraryControllerProvider.future);
    storage.failSave = true;
    scanner.songs = [songB];

    await container.read(libraryControllerProvider.notifier).scan(['/music']);

    expect(storage.saveCount, 1);
    expect(sourceStore.marked, isEmpty);
  });

  test('a second scan request is ignored while one is running', () async {
    await container.read(libraryControllerProvider.future);
    final gate = Completer<void>();
    scanner.gate = gate;
    scanner.songs = [songB];

    final first = container.read(libraryControllerProvider.notifier).scan([
      '/music',
    ]);
    await Future<void>.delayed(Duration.zero);

    await container.read(libraryControllerProvider.notifier).scan(['/music']);

    expect(scanner.scanCount, 1);

    gate.complete();
    await first;

    final state = container.read(libraryControllerProvider).requireValue;
    expect(state.songs.map((song) => song.uri), [songA.uri, songB.uri]);
  });

  test('clearing the library discards a pending scan result', () async {
    await container.read(libraryControllerProvider.future);
    final gate = Completer<void>();
    scanner.gate = gate;
    scanner.songs = [songB];

    final pendingScan = container.read(libraryControllerProvider.notifier).scan(
      ['/music'],
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(libraryControllerProvider).requireValue.isScanning,
      isTrue,
    );

    await container.read(libraryControllerProvider.notifier).clearLibrary();
    expect(storage.clearCount, 1);
    expect(
      container.read(libraryControllerProvider).requireValue.songs,
      isEmpty,
    );

    gate.complete();
    await pendingScan;

    final state = container.read(libraryControllerProvider).requireValue;
    expect(state.songs, isEmpty);
    expect(state.isScanning, isFalse);
    expect(storage.songs, isEmpty);
  });
}

class FakeLibraryStorage extends LibraryStorage {
  FakeLibraryStorage(this.songs);

  List<Song> songs;
  int saveCount = 0;
  int clearCount = 0;
  bool failSave = false;

  @override
  Future<List<Song>> load() async => List.unmodifiable(songs);

  @override
  Future<void> save(List<Song> songs) async {
    saveCount += 1;
    if (failSave) throw StateError('save failed');
    this.songs = List.of(songs);
  }

  @override
  Future<void> clear() async {
    songs = [];
    clearCount += 1;
  }
}

class FakeMusicSourceStore extends MusicSourceStore {
  FakeMusicSourceStore() : super(FakePersistenceService());

  final List<String> marked = [];

  @override
  Future<void> markScanned(String sourceId, DateTime time) async {
    marked.add(sourceId);
  }
}

class FakeMusicSourcesController extends MusicSourcesController {
  @override
  Future<MusicSourcesState> build() async {
    return const MusicSourcesState(
      sources: [
        MusicSourceConfig(
          id: 'local',
          name: '本地音乐',
          kind: MusicSourceKind.localDirectory,
        ),
      ],
    );
  }
}

class FakeMusicScanner extends CrossPlatformMusicScannerImpl {
  List<Song> songs = const [];
  List<String> lastPaths = const [];
  Completer<void>? gate;
  int scanCount = 0;

  @override
  Future<List<Song>> scanMusicInDirectoriesWithProgress(
    List<String> directoryPaths,
    Function(double) onProgress,
  ) async {
    scanCount += 1;
    lastPaths = List.of(directoryPaths);
    onProgress(0.5);
    if (gate != null) await gate!.future;
    onProgress(1);
    return songs;
  }
}
