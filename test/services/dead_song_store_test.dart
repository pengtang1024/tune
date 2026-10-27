import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/library/application/dead_songs_controller.dart';
import 'package:tune/features/library/data/dead_song_store.dart';

import 'fake_persistence.dart';

/// A track whose playback failed stays in the library; only a mark is kept.
void main() {
  test('a failed track is marked and the mark survives a restart', () async {
    final persistence = FakePersistenceService();
    final controller = DeadSongsController(DeadSongStore(persistence));

    await controller.markFailed('tune://openverse/1');

    expect(controller.state, {'tune://openverse/1'});
    expect(DeadSongStore(persistence).read(), {'tune://openverse/1'});
  });

  test('a track that plays again loses its mark', () async {
    final persistence = FakePersistenceService();
    final controller = DeadSongsController(DeadSongStore(persistence));
    await controller.markFailed('tune://openverse/1');

    await controller.clear('tune://openverse/1');

    expect(controller.state, isEmpty);
    expect(DeadSongStore(persistence).read(), isEmpty);
  });

  test('marking the same track twice keeps one entry', () async {
    final persistence = FakePersistenceService();
    final controller = DeadSongsController(DeadSongStore(persistence));

    await controller.markFailed('tune://openverse/1');
    await controller.markFailed('tune://openverse/1');

    expect(controller.state, hasLength(1));
  });

  test('an empty answer reads as no mark', () {
    expect(DeadSongStore(FakePersistenceService()).read(), isEmpty);
  });
}
