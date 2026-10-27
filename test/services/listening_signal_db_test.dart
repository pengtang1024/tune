import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/discovery/data/listening_signal_store.dart';
import 'package:tune/features/discovery/domain/track_listening.dart';

import 'fake_persistence.dart';

/// The listening aggregates live in SQLite; the old JSON document is moved
/// in once.
void main() {
  test('a record written after the database opens is read back', () async {
    final root = await Directory.systemTemp.createTemp('tune-listening');
    addTearDown(() => root.delete(recursive: true));

    final store = ListeningSignalStore(
      FakePersistenceService(),
      supportDirectory: () async => root,
    );
    await store.init();
    await store.recordListen(
      'tune://openverse/1',
      listened: const Duration(seconds: 120),
      completed: true,
    );
    await store.recordSkip('tune://openverse/2');

    final reopened = ListeningSignalStore(
      FakePersistenceService(),
      supportDirectory: () async => root,
    );
    await reopened.init();

    final records = reopened.read();
    expect(records['tune://openverse/1']?.listens, 1);
    expect(records['tune://openverse/2']?.skips, 1);
  });

  test('the old json records move into the database', () async {
    final root = await Directory.systemTemp.createTemp('tune-listening');
    addTearDown(() => root.delete(recursive: true));

    final persistence = FakePersistenceService();
    await persistence.setString(
      'discovery_listening_v1',
      jsonEncode({
        'version': 1,
        'tracks': {
          'tune://openverse/1': const TrackListening(listens: 2).toJson(),
        },
      }),
    );

    final store = ListeningSignalStore(
      persistence,
      supportDirectory: () async => root,
    );
    await store.init();

    expect(store.read()['tune://openverse/1']?.listens, 2);
  });
}
