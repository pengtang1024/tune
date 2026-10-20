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

  group('where a track lives', () {
    const remote = Song(
      id: 1,
      uri: 'tune://openverse/one',
      streamUrl: 'https://cdn.example.com/one.mp3',
    );

    const copy = Song(
      id: 1,
      uri: 'tune://openverse/one',
      localPath: '/music/Artist/One/One.mp3',
    );

    test('a remote track is remote and has no file', () {
      expect(remote.hasRemoteSource, isTrue);
      expect(remote.hasLocalFile, isFalse);
    });

    test('a track that was fetched keeps its source and owns a file', () {
      expect(copy.hasRemoteSource, isTrue);
      expect(copy.hasLocalFile, isTrue);
    });

    test('a track of the library is local and has no source', () {
      const local = Song(id: 2, uri: '/music/two.mp3');

      expect(local.hasLocalFile, isTrue);
      expect(local.hasRemoteSource, isFalse);
    });

    test('the copy and the track of the source are one track', () {
      final merged = remote.mergeWith(copy);

      expect(merged.uri, remote.uri);
      expect(merged.localPath, copy.localPath);
      expect(merged.streamUrl, remote.streamUrl);
      expect(merged.hasLocalFile, isTrue);
      expect(merged.hasRemoteSource, isTrue);
    });

    test('the merged track keeps what only the file knows', () {
      const file = Song(
        id: 1,
        uri: 'tune://openverse/one',
        localPath: '/music/Artist/One/One.mp3',
        albumArtPath: '/music/Artist/One/One.jpg',
        size: 4096,
        bitrate: 320,
        sampleRate: 44100,
      );

      final merged = remote.mergeWith(file);

      expect(merged.albumArtPath, file.albumArtPath);
      expect(merged.size, file.size);
      expect(merged.bitrate, file.bitrate);
      expect(merged.sampleRate, file.sampleRate);
      // The source knows the name of the track, the file keeps its own.
      expect(merged.title, remote.title);
    });

    test('the merge does not depend on the order of the entries', () {
      final one = remote.mergeWith(copy);
      final other = copy.mergeWith(remote);

      expect(other.localPath, one.localPath);
      expect(other.streamUrl, one.streamUrl);
      expect(other.uri, one.uri);
    });
  });

  group('the addresses of a track', () {
    test('a track of the library is its own file', () {
      const local = Song(id: 1, uri: '/music/one.flac');

      expect(local.localFile, '/music/one.flac');
      expect(local.onlineAddress, isNull);
    });

    test('a track that was fetched knows its copy', () {
      const copy = Song(
        id: 1,
        uri: 'tune://openverse/one',
        streamUrl: 'https://cdn.test/one.mp3',
        localPath: '/music/Artist/One/One.mp3',
      );

      expect(copy.localFile, '/music/Artist/One/One.mp3');
      expect(copy.onlineAddress, 'https://cdn.test/one.mp3');
    });

    test('a track of a source is played from its address', () {
      const remote = Song(
        id: 1,
        uri: 'tune://openverse/one',
        streamUrl: 'https://cdn.test/one.mp3',
      );

      expect(remote.localFile, isNull);
      expect(remote.onlineAddress, 'https://cdn.test/one.mp3');
    });

    test('an older track keeps the address it was found under', () {
      const older = Song(id: 1, uri: 'https://cdn.test/one.mp3');

      expect(older.onlineAddress, 'https://cdn.test/one.mp3');
    });
  });
}
