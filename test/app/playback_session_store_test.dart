import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/data/playback_session_store.dart';
import 'package:tune/features/player/domain/play_mode.dart';

import '../services/fake_persistence.dart';

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

  test('a session survives a round trip', () async {
    final persistence = FakePersistenceService();
    final store = PlaybackSessionStore(persistence);

    await store.saveQueue(
      queue: const [songA, songB, songC],
      currentUri: songB.uri,
      playMode: PlayMode.shuffle,
      history: [songA.uri],
    );
    await store.savePosition(songB.uri, const Duration(seconds: 42));
    await store.saveVolume(0.4);

    final session = store.readSession();
    expect(session, isNotNull);
    expect(session!.queue.map((song) => song.uri), [
      songA.uri,
      songB.uri,
      songC.uri,
    ]);
    expect(session.currentUri, songB.uri);
    expect(session.currentSong.title, 'Beta');
    expect(session.position, const Duration(seconds: 42));
    expect(session.playMode, PlayMode.shuffle);
    expect(session.history, [songA.uri]);
    expect(store.readVolume(), 0.4);
  });

  test('a position of another track is ignored', () async {
    final persistence = FakePersistenceService();
    final store = PlaybackSessionStore(persistence);

    await store.saveQueue(
      queue: const [songA, songB],
      currentUri: songB.uri,
      playMode: PlayMode.sequential,
      history: const [],
    );
    await store.savePosition(songA.uri, const Duration(minutes: 1));

    expect(store.readSession()!.position, Duration.zero);
  });

  test('a broken document means no session', () async {
    final persistence = FakePersistenceService();
    persistence.values[PlaybackSessionStore.queueKey] = '{not json';

    expect(PlaybackSessionStore(persistence).readSession(), isNull);
  });

  test('empty and repeated tracks are left out of the queue', () async {
    final persistence = FakePersistenceService();
    final store = PlaybackSessionStore(persistence);

    persistence.values[PlaybackSessionStore.queueKey] =
        '{"queue":[{"id":1,"title":"Alpha","uri":"/music/a.mp3"},'
        '{"id":2,"title":"Empty","uri":""},'
        '{"id":3,"title":"Alpha again","uri":"/music/a.mp3"}],'
        '"currentUri":"/music/a.mp3","playMode":"sequential","history":[]}';

    final session = store.readSession();
    expect(session, isNotNull);
    expect(session!.queue, hasLength(1));
    expect(session.currentUri, '/music/a.mp3');
  });

  test('a history entry that left the queue is dropped', () async {
    final persistence = FakePersistenceService();
    final store = PlaybackSessionStore(persistence);

    await store.saveQueue(
      queue: const [songA, songB],
      currentUri: songB.uri,
      playMode: PlayMode.sequential,
      history: ['/music/removed.mp3', songA.uri],
    );

    expect(store.readSession()!.history, [songA.uri]);
  });

  test('the last second starts from the beginning', () async {
    final persistence = FakePersistenceService();
    final store = PlaybackSessionStore(persistence);

    await store.saveQueue(
      queue: const [songA],
      currentUri: songA.uri,
      playMode: PlayMode.sequential,
      history: const [],
    );
    await store.savePosition(songA.uri, const Duration(milliseconds: 179500));

    expect(store.readSession()!.position, Duration.zero);
  });
}
