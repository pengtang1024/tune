import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/discovery/data/discovery_feedback_store.dart';

import 'fake_persistence.dart';

void main() {
  final now = DateTime(2026, 10, 24, 12);
  late FakePersistenceService persistence;
  late DiscoveryFeedbackStore store;

  setUp(() {
    persistence = FakePersistenceService();
    store = DiscoveryFeedbackStore(persistence);
  });

  test('a mark is read back', () async {
    await store.dismiss('/music/a.mp3', now: now);

    expect(store.read(now: now), {'/music/a.mp3': now});
    expect(store.read(now: now.add(const Duration(days: 29))), isNotEmpty);
  });

  test('a mark expires after thirty days', () async {
    await store.dismiss('/music/a.mp3', now: now);

    expect(store.read(now: now.add(const Duration(days: 30))), isEmpty);
  });

  test('a mark can be taken away', () async {
    await store.dismiss('/music/a.mp3', now: now);
    await store.remove('/music/a.mp3');

    expect(store.read(now: now), isEmpty);
    expect(persistence.containsKey(DiscoveryFeedbackStore.key), isFalse);
  });

  test('a broken document is read as empty', () async {
    await persistence.setString(DiscoveryFeedbackStore.key, 'not json');

    expect(store.read(now: now), isEmpty);
  });

  test('an unknown version is read as empty', () async {
    await persistence.setString(
      DiscoveryFeedbackStore.key,
      '{"version":99,"tracks":{"/music/a.mp3":{"createdAt":1}}}',
    );

    expect(store.read(now: now), isEmpty);
  });

  test('clearing removes the file', () async {
    await store.dismiss('/music/a.mp3', now: now);
    await store.clear();

    expect(store.read(now: now), isEmpty);
    expect(persistence.containsKey(DiscoveryFeedbackStore.key), isFalse);
  });

  test('an artist mark is kept apart from a track mark', () async {
    final tracks = DiscoveryFeedbackStore(persistence);
    final artists = DiscoveryArtistFeedbackStore(persistence);

    await tracks.dismiss('/music/a.mp3', now: now);
    await artists.dismiss('nujabes', now: now);

    expect(tracks.read(now: now), contains('/music/a.mp3'));
    expect(artists.read(now: now), contains('nujabes'));
    expect(artists.read(now: now), isNot(contains('/music/a.mp3')));

    await artists.clear();
    expect(artists.read(now: now), isEmpty);
    expect(tracks.read(now: now), contains('/music/a.mp3'));
  });
}
