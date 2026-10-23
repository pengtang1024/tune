import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/data/playback_session_store.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_state.dart';

import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

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

  late FakeAudioPlayerService audio;
  late FakeSongDownloadService downloads;
  late FakeStreamUrlResolver resolver;

  setUp(() {
    audio = FakeAudioPlayerService();
    downloads = FakeSongDownloadService();
    resolver = FakeStreamUrlResolver();
  });

  tearDown(() {
    audio.dispose();
  });

  Future<PlaybackSessionStore> savedStore() async {
    final store = PlaybackSessionStore(FakePersistenceService());
    await store.saveQueue(
      queue: const [songA, songB],
      currentUri: songB.uri,
      playMode: PlayMode.shuffle,
      history: [songA.uri],
    );
    await store.savePosition(songB.uri, const Duration(seconds: 42));
    await store.saveVolume(0.4);
    return store;
  }

  test('a start restores the queue paused at its last position', () async {
    final controller = PlaybackController(
      audio,
      downloads,
      resolver,
      sessionStore: await savedStore(),
    );
    addTearDown(controller.dispose);

    expect(controller.state.status, PlaybackStatus.paused);
    expect(controller.state.queue, [songA, songB]);
    expect(controller.state.currentUri, songB.uri);
    expect(controller.state.currentSong, songB);
    expect(controller.state.position, const Duration(seconds: 42));
    expect(controller.state.duration, const Duration(seconds: 120));
    expect(controller.state.playMode, PlayMode.shuffle);
    expect(controller.state.history, [songA.uri]);
    expect(controller.state.volume, 0.4);
    expect(audio.volume, 0.4);
  });

  test('an empty backend does not replace the saved position', () async {
    final controller = PlaybackController(
      audio,
      downloads,
      resolver,
      sessionStore: await savedStore(),
    );
    addTearDown(controller.dispose);

    audio.emitPosition(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(controller.state.position, const Duration(seconds: 42));
  });

  test('play continues a restored track at the saved position', () async {
    final controller = PlaybackController(
      audio,
      downloads,
      resolver,
      sessionStore: await savedStore(),
    );
    addTearDown(controller.dispose);

    await controller.resume();

    expect(audio.playedSong, songB);
    expect(audio.currentPosition, const Duration(seconds: 42));
    expect(controller.state.status, PlaybackStatus.playing);
  });

  test('the switch can leave the start empty but keeps the volume', () async {
    final controller = PlaybackController(
      audio,
      downloads,
      resolver,
      sessionStore: await savedStore(),
      restoreSession: false,
    );
    addTearDown(controller.dispose);

    expect(controller.state.queue, isEmpty);
    expect(controller.state.currentSong, isNull);
    expect(controller.state.status, PlaybackStatus.idle);
    expect(controller.state.volume, 0.4);
    expect(audio.volume, 0.4);
  });

  test('a start with the switch off keeps the saved session', () async {
    final store = await savedStore();
    final controller = PlaybackController(
      audio,
      downloads,
      resolver,
      sessionStore: store,
      restoreSession: false,
    );

    controller.dispose();

    final session = store.readSession();
    expect(session, isNotNull);
    expect(session!.currentUri, songB.uri);
    expect(session.position, const Duration(seconds: 42));
  });

  test(
    'a queue played with the switch off replaces the saved session',
    () async {
      final store = await savedStore();
      final controller = PlaybackController(
        audio,
        downloads,
        resolver,
        sessionStore: store,
        restoreSession: false,
      );

      await controller.playQueue(const [songA]);
      controller.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final session = store.readSession();
      expect(session, isNotNull);
      expect(session!.queue, [songA]);
      expect(session.currentUri, songA.uri);
    },
  );

  test('the queue and position are written when the player closes', () async {
    final persistence = FakePersistenceService();
    final store = PlaybackSessionStore(persistence);
    final controller = PlaybackController(
      audio,
      downloads,
      resolver,
      sessionStore: store,
    );

    await controller.playQueue(const [songA, songB]);
    audio.emitPosition(const Duration(seconds: 12));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    controller.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final queueDoc =
        jsonDecode(persistence.getString(PlaybackSessionStore.queueKey)!)
            as Map<String, dynamic>;
    expect(queueDoc['currentUri'], songA.uri);
    expect((queueDoc['queue'] as List), hasLength(2));

    final positionDoc =
        jsonDecode(persistence.getString(PlaybackSessionStore.positionKey)!)
            as Map<String, dynamic>;
    expect(positionDoc['uri'], songA.uri);
    expect(positionDoc['positionMs'], 12000);
  });

  test('clearing the queue drops the saved session', () async {
    final persistence = FakePersistenceService();
    final store = PlaybackSessionStore(persistence);
    await store.saveQueue(
      queue: const [songA, songB],
      currentUri: songB.uri,
      playMode: PlayMode.sequential,
      history: const [],
    );
    await store.savePosition(songB.uri, const Duration(seconds: 10));

    final controller = PlaybackController(
      audio,
      downloads,
      resolver,
      sessionStore: store,
    );

    await controller.clearQueue();
    controller.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(store.readSession(), isNull);
    expect(persistence.getString(PlaybackSessionStore.positionKey), isNull);
  });
}
