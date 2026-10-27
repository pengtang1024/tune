import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/domain/library_cache_limit.dart';

/// A limit trims the remote sources to their newest tracks; the local files
/// stay, and zero means no limit at all.
void main() {
  Song remote(int id, int added) => Song(
    id: id,
    title: 'Remote $id',
    uri: 'tune://openverse/$id',
    sourceId: 'openverse',
    externalId: '$id',
    dateAdded: added,
  );

  const local = Song(id: 9, title: 'Local', uri: '/music/local.mp3');

  test('zero keeps every track', () {
    final songs = [remote(1, 1), remote(2, 2), local];

    expect(applyCacheLimit(songs, 0), songs);
  });

  test('a limit keeps the newest tracks of a source', () {
    final songs = [remote(1, 1), remote(2, 2), remote(3, 3), local];

    final kept = applyCacheLimit(songs, 2);

    expect(
      kept
          .where((song) => song.sourceId == 'openverse')
          .map((s) => s.id)
          .toSet(),
      {2, 3},
    );
    expect(kept.where((song) => song.sourceId == null), hasLength(1));
  });

  test('each source is limited on its own', () {
    final other = Song(
      id: 8,
      title: 'Other',
      uri: 'tune://jamendo/8',
      sourceId: 'jamendo',
      dateAdded: 1,
    );
    final songs = [remote(1, 1), remote(2, 2), other];

    final kept = applyCacheLimit(songs, 1);

    expect(kept.map((song) => song.sourceId).toSet(), {'openverse', 'jamendo'});
    expect(kept.where((song) => song.sourceId == 'openverse').single.id, 2);
  });
}
