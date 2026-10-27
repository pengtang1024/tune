import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/plex_source.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Plex answers in XML and keeps the music in one section of the library.
///
/// The tests below read the answers of a server: which section holds the
/// music, what one track becomes, and where the scan looks with and without
/// a keyword.
void main() {
  group('Plex adapter', () {
    test('finds the music section of the library', () {
      expect(PlexSourceAdapter.musicSectionKey(_sectionsXml()), '2');
      expect(PlexSourceAdapter.musicSectionKey(_noMusicSectionsXml()), isNull);
      expect(PlexSourceAdapter.musicSectionKey(null), isNull);
    });

    test('maps a track of the library', () {
      final songs = PlexSourceAdapter.parseTracks(
        _tracksXml(),
        sourceId: 'plex',
        server: 'http://localhost:32400',
        token: 'secret',
      );

      expect(songs, hasLength(1));
      final song = songs.single;
      expect(song.title, 'In Chancery');
      expect(song.artist, 'Charles Dickens');
      expect(song.album, 'Bleak House');
      expect(song.duration, 1582000);
      expect(
        song.streamUrl,
        'http://localhost:32400/library/parts/1/file.mp3?X-Plex-Token=secret',
      );
      expect(
        song.artworkUrl,
        'http://localhost:32400/library/metadata/10/thumb/1?X-Plex-Token=secret',
      );
      expect(song.year, 1853);
      expect(song.bitrate, 320);
      expect(song.trackNumber, 1);
      expect(song.size, 5105833);
      expect(song.externalId, '10');
    });

    test('a track without a file is not kept', () {
      final xml = _tracksXml().replaceFirst(
        '<Part id="1" key="/library/parts/1/file.mp3" size="5105833" />',
        '',
      );

      expect(
        PlexSourceAdapter.parseTracks(
          xml,
          sourceId: 'plex',
          server: 'http://localhost:32400',
          token: 'secret',
        ),
        isEmpty,
      );
    });

    test('a track of the library is kept only once', () {
      final xml = _tracksXml().replaceFirst(
        '</MediaContainer>',
        '<Track ratingKey="10" title="In Chancery" grandparentTitle="Charles Dickens" parentTitle="Bleak House" duration="1582000"><Media><Part key="/library/parts/1/file.mp3" /></Media></Track></MediaContainer>',
      );

      expect(
        PlexSourceAdapter.parseTracks(
          xml,
          sourceId: 'plex',
          server: 'http://localhost:32400',
          token: 'secret',
        ),
        hasLength(1),
      );
    });

    test('the address of a server is kept without a trailing slash', () {
      expect(
        PlexSourceAdapter.normalizeServer('192.168.1.10:32400/'),
        'http://192.168.1.10:32400',
      );
      expect(PlexSourceAdapter.normalizeServer('  '), isNull);
    });

    test('a scan without a keyword reads the music section', () async {
      final answers = _Replies([_sectionsXml(), _tracksXml()]);

      final result = await PlexSourceAdapter(dio: answers.dio).scan(
        _request('plex', const {'server': 'http://x:32400', 'token': 'secret'}),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(1));
      expect(answers.uris[0].path, '/library/sections');
      expect(answers.uris[0].queryParameters['X-Plex-Token'], 'secret');
      expect(answers.uris[1].path, '/library/sections/2/all');
      expect(answers.uris[1].queryParameters['type'], '10');
    });

    test('a scan with a keyword searches the library', () async {
      final answers = _Replies([_tracksXml()]);

      final result = await PlexSourceAdapter(dio: answers.dio).scan(
        _request('plex', const {
          'server': 'http://x:32400',
          'token': 'secret',
          'query': 'Dickens',
        }),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(1));
      expect(answers.uris.single.path, '/library/search');
      expect(answers.uris.single.queryParameters['query'], 'Dickens');
    });

    test('a server without a music section reads as no track', () async {
      final answers = _Replies([_noMusicSectionsXml()]);

      final result = await PlexSourceAdapter(dio: answers.dio).scan(
        _request('plex', const {'server': 'http://x:32400', 'token': 'secret'}),
      );

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, isEmpty);
      expect(result.message, AppStrings.instance.plexNoMatch);
    });
  });
}

String _sectionsXml() => '''
<?xml version="1.0" encoding="UTF-8"?>
<MediaContainer size="2">
  <Directory key="1" type="movie" title="Films" />
  <Directory key="2" type="artist" title="Music" />
</MediaContainer>
''';

String _noMusicSectionsXml() => '''
<?xml version="1.0" encoding="UTF-8"?>
<MediaContainer size="1">
  <Directory key="1" type="movie" title="Films" />
</MediaContainer>
''';

String _tracksXml() => '''
<?xml version="1.0" encoding="UTF-8"?>
<MediaContainer size="1">
  <Track ratingKey="10" key="/library/metadata/10" title="In Chancery"
      grandparentTitle="Charles Dickens" parentTitle="Bleak House"
      duration="1582000" parentYear="1853" bitrate="320" index="1"
      thumb="/library/metadata/10/thumb/1">
    <Media id="1" duration="1582000" bitrate="320" audioCodec="mp3">
      <Part id="1" key="/library/parts/1/file.mp3" size="5105833" />
    </Media>
  </Track>
</MediaContainer>
''';

/// One scan of the server.
MusicSourceScanRequest _request(String id, Map<String, String> settings) {
  return MusicSourceScanRequest(
    config: MusicSourceConfig(
      id: id,
      type: id,
      name: id,
      kind: MusicSourceKind.openApi,
      settings: settings,
    ),
  );
}

/// A Dio that answers every request with its replies in a loop.
class _Replies {
  _Replies(List<Object> bodies) : _bodies = bodies;

  final List<Object> _bodies;
  var _next = 0;
  final uris = <Uri>[];

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          uris.add(options.uri);
          final body = _bodies[_next % _bodies.length];
          _next++;
          handler.resolve(
            Response(requestOptions: options, data: body, statusCode: 200),
          );
        },
      ),
    );
    return client;
  }
}
