import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/audio_source_address.dart';
import 'package:tune/domain/models/song.dart';

void main() {
  const localSong = Song(id: 1, title: 'One', uri: '/music/one.mp3');

  const remoteSong = Song(
    id: 2,
    title: 'Two',
    uri: 'tune://openverse/two',
    streamUrl: 'https://cdn.example.com/two.mp3',
  );

  group('the address the backend loads', () {
    test('a local track is read from the disk', () {
      final address = audioSourceAddress(
        localSong,
        localSong.playbackUri,
        fromStore: false,
      );

      expect(address.scheme, 'file');
      expect(address.path, '/music/one.mp3');
    });

    test('a remote track is streamed from the network', () {
      final address = audioSourceAddress(
        remoteSong,
        remoteSong.playbackUri,
        fromStore: false,
      );

      expect(address.scheme, 'https');
      expect(address.host, 'cdn.example.com');
    });

    test('a stored copy is read from the disk', () {
      final address = audioSourceAddress(
        remoteSong,
        '/music/two.mp3',
        fromStore: true,
      );

      expect(address.scheme, 'file');
      expect(address.path, '/music/two.mp3');
    });

    test('a path that carries a colon stays a file', () {
      // A canonical URI of a remote source names the track; a path that was
      // built from it must not turn into an address of a foreign scheme.
      final address = audioSourceAddress(
        remoteSong,
        'tune://openverse/two.mp3',
        fromStore: true,
      );

      expect(address.scheme, 'file');
      expect(address.path, endsWith('openverse/two.mp3'));
    });
  });
}
