import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';

void main() {
  group('Song model', () {
    test('fromMap creates a valid Song', () {
      final song = Song.fromMap({
        'id': 1,
        'title': 'Test',
        'artist': 'Artist',
        'album': 'Album',
        'duration': 240000,
      });

      expect(song.id, 1);
      expect(song.title, 'Test');
      expect(song.artist, 'Artist');
      expect(song.durationInMillis, 240000);
    });

    test('copyWith preserves unchanged fields', () {
      final song = Song.fromMap({'id': 1, 'title': 'A', 'artist': 'B'});
      final copy = song.copyWith(title: 'C');

      expect(copy.title, 'C');
      expect(copy.artist, 'B');
      expect(copy.id, 1);
    });

    test('named constructor applies defaults', () {
      const song = Song(id: 42);

      expect(song.id, 42);
      expect(song.title, '');
      expect(song.isFavorite, isFalse);
    });

    test('equality is based on id', () {
      final a = Song.fromMap({'id': 1, 'title': 'X'});
      final b = Song.fromMap({'id': 1, 'title': 'Y'});

      expect(a, b);
    });

    test('JSON round-trip preserves core fields', () {
      final original = Song.fromMap({
        'id': 1,
        'title': 'T',
        'artist': 'A',
        'album': 'B',
        'duration': 1000,
        'uri': '/path',
        'bitrate': 320,
      });

      final restored = Song.fromMap(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.bitrate, original.bitrate);
    });
  });

  group('the file of a track', () {
    test('a track that lives on the disk owns a file', () {
      const song = Song(id: 1, uri: '/music/one.mp3');

      expect(song.isLocalFile, isTrue);
    });

    test('a remote track owns a file only after it was fetched', () {
      const song = Song(
        id: 1,
        uri: 'tune://openverse/one',
        streamUrl: 'https://cdn.example.com/one.mp3',
      );

      // The canonical URI names the track, it is not a path.
      expect(song.isLocalFile, isFalse);
      expect(song.isRemote, isTrue);
    });

    test('a network address is not a file', () {
      const song = Song(id: 1, uri: 'https://source.test/one');

      expect(song.isLocalFile, isFalse);
    });
  });
}
