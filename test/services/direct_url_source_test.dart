import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/direct_url_source.dart';
import 'package:tune/domain/models/music_source.dart';

/// The reader brings the tracks along by their address.
///
/// There is no service behind this source: the app only plays what the
/// address points at, so the parsing of the addresses is the whole type.
void main() {
  group('the addresses of a direct source', () {
    test('one address per line', () {
      const raw = 'https://example.com/a.mp3\nhttps://example.com/b.flac';

      expect(DirectUrlSourceAdapter.parseAddresses(raw), [
        'https://example.com/a.mp3',
        'https://example.com/b.flac',
      ]);
    });

    test('the empty lines and the ones that are not addresses are dropped', () {
      const raw = '''
  https://example.com/a.mp3

not an address
ftp://example.com/c.mp3
''';

      expect(DirectUrlSourceAdapter.parseAddresses(raw), [
        'https://example.com/a.mp3',
      ]);
    });

    test('a source without an address is not configured', () {
      const config = MusicSourceConfig(
        id: 'direct_url-1',
        type: 'direct_url',
        name: '直链音频',
        kind: MusicSourceKind.custom,
      );
      final adapter = DirectUrlSourceAdapter();

      expect(adapter.isConfigured(config), isFalse);
      expect(
        adapter.isConfigured(
          config.copyWith(settings: {'urls': 'https://example.com/a.mp3'}),
        ),
        isTrue,
      );
    });
  });

  group('the tracks of a direct source', () {
    test('every address becomes a track', () {
      final songs = DirectUrlSourceAdapter.parseTracks(
        ['https://example.com/music/Song.mp3'],
        sourceId: 'direct_url-1',
      );

      expect(songs.single.title, 'Song');
      expect(songs.single.streamUrl, 'https://example.com/music/Song.mp3');
      expect(songs.single.sourceId, 'direct_url-1');
      expect(
        songs.single.uri,
        'tune://direct_url-1/https%3A%2F%2Fexample.com%2Fmusic%2FSong.mp3',
      );
    });

    test('the title of an address without a file name is the host', () {
      expect(
        DirectUrlSourceAdapter.titleOf('https://example.com'),
        'example.com',
      );
      expect(
        DirectUrlSourceAdapter.titleOf('https://example.com/'),
        'example.com',
      );
    });

    test('the title of an address with a path is the last name in it', () {
      expect(
        DirectUrlSourceAdapter.titleOf('https://example.com/stream?id=1'),
        'stream',
      );
    });

    test('the title keeps the name of the file without its extension', () {
      expect(
        DirectUrlSourceAdapter.titleOf('https://example.com/music/01%20Song.mp3'),
        '01 Song',
      );
    });
  });
}
