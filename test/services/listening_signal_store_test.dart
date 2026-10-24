import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/discovery/data/listening_signal_store.dart';

import 'fake_persistence.dart';

void main() {
  final now = DateTime(2026, 10, 24, 12);
  late FakePersistenceService persistence;
  late ListeningSignalStore store;

  setUp(() {
    persistence = FakePersistenceService();
    store = ListeningSignalStore(persistence);
  });

  test('a listened track is summarized', () async {
    await store.recordListen(
      '/music/a.mp3',
      listened: const Duration(seconds: 62),
      completed: true,
      at: now,
    );

    final signal = store.read()['/music/a.mp3']!;
    expect(signal.listens, 1);
    expect(signal.skips, 0);
    expect(signal.completions, 1);
    expect(signal.listenedMs, 62000);
    expect(signal.lastPlayedAt, now);
  });

  test('a skip is summarized without a listen', () async {
    await store.recordSkip('/music/a.mp3', at: now);

    final signal = store.read()['/music/a.mp3']!;
    expect(signal.listens, 0);
    expect(signal.skips, 1);
    expect(signal.lastPlayedAt, now);
  });

  test('a broken document is read as empty', () async {
    await persistence.setString(ListeningSignalStore.key, 'not json');

    expect(store.read(), isEmpty);
  });

  test('an unknown version is read as empty', () async {
    await persistence.setString(
      ListeningSignalStore.key,
      '{"version":99,"tracks":{"/music/a.mp3":{"listens":2}}}',
    );

    expect(store.read(), isEmpty);
  });

  test('the store keeps the most recent tracks only', () async {
    final tracks = <String, dynamic>{
      for (var index = 0; index < ListeningSignalStore.maxTracks + 5; index++)
        '/music/$index.mp3': {
          'listens': 1,
          'skips': 0,
          'completions': 0,
          'listenedMs': 1000,
          'lastPlayedAt': now
              .subtract(Duration(minutes: index))
              .millisecondsSinceEpoch,
        },
    };
    await persistence.setString(
      ListeningSignalStore.key,
      jsonEncode({'version': 1, 'tracks': tracks}),
    );

    await store.recordSkip('/music/new.mp3', at: now);

    final signals = store.read();
    expect(signals.length, ListeningSignalStore.maxTracks);
    expect(signals, contains('/music/new.mp3'));
    expect(signals, isNot(contains('/music/2004.mp3')));
  });

  test('clearing removes the file', () async {
    await store.recordSkip('/music/a.mp3', at: now);
    await store.clear();

    expect(store.read(), isEmpty);
    expect(persistence.containsKey(ListeningSignalStore.key), isFalse);
  });
}
