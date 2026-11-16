import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/application/discovery_controller.dart';
import 'package:tune/features/discovery/data/discovery_feedback_store.dart';
import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/discovery/domain/discovery_state.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';
import 'compact_layout_test.dart' show FakeLibraryController;
import 'music_sources_section_test.dart' show FakeMusicSourcesController;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Song song(int id, {String artist = 'Artist'}) {
    return Song(
      id: id,
      title: 'Song $id',
      artist: artist,
      album: 'Album $id',
      uri: '/music/$id.mp3',
      dateAdded: DateTime.now().millisecondsSinceEpoch,
    );
  }

  final songs = [
    for (var index = 0; index < 30; index++)
      song(index, artist: index < 6 ? 'Nujabes' : 'Artist $index'),
  ];

  ProviderContainer createContainer(
    FakePersistenceService persistence, {
    MusicSourceService? sourceService,
    MusicSourcesState? sources,
  }) {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final playback = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    final container = ProviderContainer(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(audio),
        playbackControllerProvider.overrideWith((ref) => playback),
        persistenceServiceProvider.overrideWithValue(persistence),
        libraryControllerProvider.overrideWith(
          () => FakeLibraryController(LibraryState(songs: songs)),
        ),
        musicSourcesControllerProvider.overrideWith(
          () => FakeMusicSourcesController(
            sources ??
                MusicSourcesState(sources: BuiltInMusicSources.defaults),
          ),
        ),
        if (sourceService != null)
          musicSourceServiceProvider.overrideWithValue(sourceService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> keepAlive(ProviderContainer container) async {
    container.listen(discoveryControllerProvider, (previous, next) {});
    await container.read(discoveryControllerProvider.future);
  }

  test('the page is a projection of the library', () async {
    final container = createContainer(FakePersistenceService());
    await keepAlive(container);

    final state = container.read(discoveryControllerProvider).requireValue;
    expect(state.sections, isNotEmpty);
    expect(
      state.sections.any(
        (section) => section.kind == DiscoverySectionKind.dailyMix,
      ),
      isTrue,
    );
  });

  test('a heart gives the artist a shelf', () async {
    final container = createContainer(FakePersistenceService());
    await keepAlive(container);

    for (var index = 0; index < 2; index++) {
      await container
          .read(favoritesControllerProvider.notifier)
          .mark('/music/$index.mp3');
    }
    await container.read(discoveryControllerProvider.future);

    final state = container.read(discoveryControllerProvider).requireValue;
    final artistSections = state.sections.where(
      (section) => section.kind == DiscoverySectionKind.artist,
    );
    expect(artistSections, isNotEmpty);
    expect(artistSections.first.reason.artist, 'Nujabes');
  });

  test('a dismissal is removed and survives a restart', () async {
    final persistence = FakePersistenceService();
    final container = createContainer(persistence);
    await keepAlive(container);

    final first = container
        .read(discoveryControllerProvider)
        .requireValue
        .sections
        .first;
    final uri = first.tracks.first.song.uri;
    await container.read(discoveryControllerProvider.notifier).dismiss(uri);

    final after = container.read(discoveryControllerProvider).requireValue;
    final uris = {
      for (final section in after.sections)
        for (final track in section.tracks) track.song.uri,
    };
    expect(uris, isNot(contains(uri)));
    expect(persistence.getString(DiscoveryFeedbackStore.key), contains(uri));

    final restarted = createContainer(persistence);
    await keepAlive(restarted);
    final restartedUris = {
      for (final section
          in restarted.read(discoveryControllerProvider).requireValue.sections)
        for (final track in section.tracks) track.song.uri,
    };
    expect(restartedUris, isNot(contains(uri)));
  });

  test('undo brings a dismissed track back', () async {
    final container = createContainer(FakePersistenceService());
    await keepAlive(container);

    final uri = container
        .read(discoveryControllerProvider)
        .requireValue
        .sections
        .first
        .tracks
        .first
        .song
        .uri;
    final controller = container.read(discoveryControllerProvider.notifier);
    await controller.dismiss(uri);
    await controller.forgetDismissal(uri);

    final uris = {
      for (final section
          in container.read(discoveryControllerProvider).requireValue.sections)
        for (final track in section.tracks) track.song.uri,
    };
    expect(uris, contains(uri));
  });

  test('clearing feedback leaves the favorites alone', () async {
    final container = createContainer(FakePersistenceService());
    await keepAlive(container);
    await container
        .read(favoritesControllerProvider.notifier)
        .mark('/music/0.mp3');
    final uri = container
        .read(discoveryControllerProvider)
        .requireValue
        .sections
        .first
        .tracks
        .first
        .song
        .uri;
    final controller = container.read(discoveryControllerProvider.notifier);
    await controller.dismiss(uri);
    await controller.clearFeedback();

    expect(
      container.read(favoritesControllerProvider).contains('/music/0.mp3'),
      isTrue,
    );
    final state = container.read(discoveryControllerProvider).requireValue;
    expect(
      state.sections.any(
        (section) => section.kind == DiscoverySectionKind.dailyMix,
      ),
      isTrue,
    );
  });

  test('an explicit artist lookup adds a transient online section', () async {
    final service = FakeDiscoverySourceService();
    final container = createContainer(
      FakePersistenceService(),
      sourceService: service,
    );
    await keepAlive(container);

    final result = await container
        .read(discoveryControllerProvider.notifier)
        .findMoreByArtist('Nujabes');
    expect(result, DiscoveryOnlineResult.added);

    final state = container.read(discoveryControllerProvider).requireValue;
    final online = state.sections.where(
      (section) => section.kind == DiscoverySectionKind.onlineArtist,
    );
    expect(online, isNotEmpty);
    expect(online.first.tracks.length, 2);
    expect(
      online.first.tracks.every((track) => track.song.sourceId == 'openverse'),
      isTrue,
    );

    final uri = online.first.tracks.first.song.uri;
    await container.read(discoveryControllerProvider.notifier).dismiss(uri);
    final after = container.read(discoveryControllerProvider).requireValue;
    final uris = {
      for (final section in after.sections)
        for (final track in section.tracks) track.song.uri,
    };
    expect(uris, isNot(contains(uri)));
  });

  test('an artist can be shown less and brought back', () async {
    final container = createContainer(FakePersistenceService());
    await keepAlive(container);

    final controller = container.read(discoveryControllerProvider.notifier);
    await controller.dismissArtist('Nujabes');
    var artists = {
      for (final section
          in container.read(discoveryControllerProvider).requireValue.sections)
        for (final track in section.tracks) track.song.artist,
    };
    expect(artists, isNot(contains('Nujabes')));

    await controller.forgetArtistDismissal('Nujabes');
    artists = {
      for (final section
          in container.read(discoveryControllerProvider).requireValue.sections)
        for (final track in section.tracks) track.song.artist,
    };
    expect(artists, contains('Nujabes'));
  });

  test('an artist lookup without an online source says so and never searches',
      () async {
    final sourceService = FakeDiscoverySourceService();
    final container = createContainer(
      FakePersistenceService(),
      sourceService: sourceService,
      sources: MusicSourcesState(
        sources: [
          for (final source in BuiltInMusicSources.defaults)
            source.copyWith(enabled: false),
        ],
      ),
    );
    await keepAlive(container);

    final result = await container
        .read(discoveryControllerProvider.notifier)
        .findMoreByArtist('Nujabes');

    expect(result, DiscoveryOnlineResult.noSources);
    expect(sourceService.calls, 0, reason: '没有在线音源时不该发请求');
    final state = container.read(discoveryControllerProvider).requireValue;
    expect(
      state.sections.any(
        (section) => section.kind == DiscoverySectionKind.onlineArtist,
      ),
      isFalse,
    );
  });

  test('an artist lookup drops library duplicates and live streams', () async {
    final container = createContainer(
      FakePersistenceService(),
      sourceService: FakeDiscoverySourceService(
        songs: [
          Song(
            id: 2001,
            title: 'Already In The Library',
            artist: 'Nujabes',
            uri: '/music/0.mp3',
            sourceId: 'openverse',
          ),
          Song(
            id: 2002,
            title: 'Live Radio',
            artist: 'Nujabes',
            uri: 'tune://openverse/live',
            sourceId: 'openverse',
            isLiveStream: true,
          ),
          Song(
            id: 2003,
            title: 'Fresh',
            artist: 'Nujabes',
            uri: 'tune://openverse/fresh',
            sourceId: 'openverse',
            streamUrl: 'https://example.com/fresh.mp3',
          ),
        ],
      ),
    );
    await keepAlive(container);

    final result = await container
        .read(discoveryControllerProvider.notifier)
        .findMoreByArtist('Nujabes');
    expect(result, DiscoveryOnlineResult.added);

    final state = container.read(discoveryControllerProvider).requireValue;
    final online = state.sections.where(
      (section) => section.kind == DiscoverySectionKind.onlineArtist,
    );
    expect(online, hasLength(1));
    expect(
      online.first.tracks.map((track) => track.song.uri),
      ['tune://openverse/fresh'],
    );
  });

  test('a second lookup of the same artist replaces its shelf', () async {
    final container = createContainer(
      FakePersistenceService(),
      sourceService: FakeDiscoverySourceService(),
    );
    await keepAlive(container);
    final controller = container.read(discoveryControllerProvider.notifier);

    await controller.findMoreByArtist('Nujabes');
    await controller.findMoreByArtist('Nujabes');

    final state = container.read(discoveryControllerProvider).requireValue;
    final online = state.sections
        .where((section) => section.kind == DiscoverySectionKind.onlineArtist)
        .toList();
    expect(online, hasLength(1), reason: '再查一次应替换而不是叠加');
    expect(online.first.tracks, hasLength(2));
  });

  test('an artist lookup stops at twenty tracks', () async {
    final container = createContainer(
      FakePersistenceService(),
      sourceService: FakeDiscoverySourceService(
        songs: [
          for (var index = 0; index < 25; index++)
            Song(
              id: 3000 + index,
              title: 'Online $index',
              artist: 'Nujabes',
              uri: 'tune://openverse/bulk-$index',
              sourceId: 'openverse',
              streamUrl: 'https://example.com/bulk-$index.mp3',
            ),
        ],
      ),
    );
    await keepAlive(container);

    await container
        .read(discoveryControllerProvider.notifier)
        .findMoreByArtist('Nujabes');

    final state = container.read(discoveryControllerProvider).requireValue;
    final online = state.sections.firstWhere(
      (section) => section.kind == DiscoverySectionKind.onlineArtist,
    );
    expect(online.tracks, hasLength(20));
  });
}

class FakeDiscoverySourceService extends MusicSourceService {
  FakeDiscoverySourceService({List<Song>? songs}) : _songs = songs, super(
        scanner: _EmptyScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

  final List<Song>? _songs;
  int calls = 0;

  @override
  Future<List<SourceScanResult>> search({
    required List<MusicSourceConfig> sources,
    required String query,
    Map<String, int> offsets = const {},
    Map<String, String> cursors = const {},
    void Function(String sourceId, double progress)? onProgress,
  }) async {
    calls++;
    return [
      SourceScanResult(
        sourceId: 'openverse',
        status: SourceScanStatus.success,
        songs: _songs ?? _defaultSongs,
      ),
    ];
  }

  static const List<Song> _defaultSongs = [
    Song(
      id: 1001,
      title: 'Online One',
      artist: 'Nujabes',
      uri: 'tune://openverse/online-1',
      sourceId: 'openverse',
      externalId: 'online-1',
      streamUrl: 'https://example.com/online-1.mp3',
    ),
    Song(
      id: 1002,
      title: 'Online Two',
      artist: 'Nujabes feat. Someone',
      uri: 'tune://openverse/online-2',
      sourceId: 'openverse',
      externalId: 'online-2',
      streamUrl: 'https://example.com/online-2.mp3',
    ),
    Song(
      id: 1003,
      title: 'Other Artist',
      artist: 'Someone Else',
      uri: 'tune://openverse/online-3',
      sourceId: 'openverse',
      externalId: 'online-3',
      streamUrl: 'https://example.com/online-3.mp3',
    ),
  ];
}

class _EmptyScanner extends CrossPlatformMusicScannerImpl {
  @override
  Future<List<Song>> scanMusicInDirectoriesWithProgress(
    List<String> directoryPaths,
    Function(double) onProgress,
  ) async {
    return const [];
  }
}
