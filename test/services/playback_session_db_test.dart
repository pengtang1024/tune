import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/data/playback_session_store.dart';
import 'package:tune/features/player/domain/play_mode.dart';

import 'fake_persistence.dart';

/// The queue lives in SQLite; the position is a small value beside it.
void main() {
  const songA = Song(id: 1, title: 'Alpha', uri: '/music/a.mp3');
  const songB = Song(id: 2, title: 'Beta', uri: '/music/b.mp3');

  test('a saved queue is read back after a reopen', () async {
    final root = await Directory.systemTemp.createTemp('tune-session');
    addTearDown(() => root.delete(recursive: true));

    final store = PlaybackSessionStore(
      FakePersistenceService(),
      supportDirectory: () async => root,
    );
    await store.init();
    await store.saveQueue(
      queue: [songA, songB],
      currentUri: songB.uri,
      playMode: PlayMode.shuffle,
      history: [songA.uri],
    );
    await store.savePosition(songB.uri, const Duration(seconds: 42));

    final reopened = PlaybackSessionStore(
      FakePersistenceService(),
      supportDirectory: () async => root,
    );
    await reopened.init();

    final session = reopened.readSession();
    expect(session, isNotNull);
    expect(session!.queue.map((song) => song.uri), [songA.uri, songB.uri]);
    expect(session.currentUri, songB.uri);
    expect(session.playMode, PlayMode.shuffle);
    expect(session.position, const Duration(seconds: 42));
    expect(session.history, [songA.uri]);
  });

  test('the old json queue moves into the database', () async {
    final root = await Directory.systemTemp.createTemp('tune-session');
    addTearDown(() => root.delete(recursive: true));

    final persistence = FakePersistenceService();
    await persistence.setString(
      'playback_queue_v1',
      '{"queue":[{"id":1,"title":"Alpha","uri":"/music/a.mp3"}],'
          '"currentUri":"/music/a.mp3","playMode":"sequential","history":[]}',
    );

    final store = PlaybackSessionStore(
      persistence,
      supportDirectory: () async => root,
    );
    await store.init();

    expect(store.readSession()?.queue.single.uri, '/music/a.mp3');
  });

  test('clearing drops the queue and the position', () async {
    final root = await Directory.systemTemp.createTemp('tune-session');
    addTearDown(() => root.delete(recursive: true));

    final store = PlaybackSessionStore(
      FakePersistenceService(),
      supportDirectory: () async => root,
    );
    await store.init();
    await store.saveQueue(
      queue: [songA],
      currentUri: songA.uri,
      playMode: PlayMode.sequential,
      history: const [],
    );

    await store.clearSession();

    expect(store.readSession(), isNull);
  });
}
