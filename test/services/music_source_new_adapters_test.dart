import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/jellyfin_source.dart';
import 'package:tune/data/services/music_sources/wikimedia_source.dart';

void main() {
  group('Wikimedia adapter', () {
    test('maps the metadata of an audio file', () {
      final songs = WikimediaSourceAdapter.parseResults(
        _commonsAnswer(),
        sourceId: 'wikimedia',
      );

      expect(songs, hasLength(1));

      final song = songs.single;
      expect(song.title, 'Jazz at the park');
      expect(song.artist, 'Man with a metal pig');
      expect(song.album, '');
      expect(song.duration, 205721);
      expect(song.streamUrl, _commonsFile);
      expect(song.genre, 'jazz music');
      expect(song.year, 2025);
      expect(song.license, 'CC0');
      expect(song.size, 2088081);
      expect(song.description, 'Flute and Tenor Sax Jazz duo at a public park');
      expect(song.sourceId, 'wikimedia');
      expect(song.uri, 'tune://wikimedia/File%3AJazz%20at%20the%20park.ogg');
    });

    test('removes the markup and the entities of the metadata', () {
      final answer = _commonsAnswer();
      _imageInfo(answer)['extmetadata'] = {
        'ObjectName': 'Tom &amp; Jerry &quot;live&quot; &#39;set&#39;',
        'Artist': '<a href="https://example.com">A &lt;band&gt;</a>',
        'ImageDescription': '<p>Recorded &amp; mixed</p>',
      };

      final song = WikimediaSourceAdapter.parseResults(
        answer,
        sourceId: 'wikimedia',
      ).single;

      expect(song.title, 'Tom & Jerry "live" \'set\'');
      expect(song.artist, 'A <band>');
      expect(song.description, 'Recorded & mixed');
    });

    test('skips the files that cannot be played', () {
      final answer = _commonsAnswer();
      final pages = answer['query']['pages'] as Map<String, dynamic>;
      pages['2'] = _pageWith({
        'mediatype': 'VIDEO',
        'mime': 'video/webm',
      }, title: 'File:Movie.webm');
      pages['3'] = _pageWith({
        'mediatype': 'AUDIO',
        'url': '',
      }, title: 'File:Empty.ogg');
      pages['4'] = {'title': 'File:Without info.ogg'};

      final songs = WikimediaSourceAdapter.parseResults(
        answer,
        sourceId: 'wikimedia',
      );

      expect(songs, hasLength(1));
      expect(songs.single.title, 'Jazz at the park');
    });

    test('keeps every file only once', () {
      final answer = _commonsAnswer();
      final pages = answer['query']['pages'] as Map<String, dynamic>;
      pages['999'] = pages['172622974'];

      final songs = WikimediaSourceAdapter.parseResults(
        answer,
        sourceId: 'wikimedia',
      );

      expect(songs, hasLength(1));
    });

    test('falls back to the terms of use and to the file name', () {
      final answer = _commonsAnswer();
      _imageInfo(answer)['extmetadata'] = {
        'LicenseShortName': '',
        'UsageTerms': 'Creative Commons Zero',
      };

      final song = WikimediaSourceAdapter.parseResults(
        answer,
        sourceId: 'wikimedia',
      ).single;

      expect(song.license, 'Creative Commons Zero');
      expect(song.title, 'Jazz at the park.ogg');
      expect(song.genre, isNull);
      expect(song.year, isNull);
    });

    test('searches the whole wiki when no keyword is given', () {
      expect(WikimediaSourceAdapter.searchTerm(null), 'filetype:audio');
      expect(WikimediaSourceAdapter.searchTerm('  '), 'filetype:audio');
      expect(
        WikimediaSourceAdapter.searchTerm('piano'),
        'filetype:audio piano',
      );
    });

    test('answers an empty response with no track', () {
      expect(
        WikimediaSourceAdapter.parseResults({}, sourceId: 'wikimedia'),
        isEmpty,
      );
    });
  });

  group('Jellyfin adapter', () {
    test('maps the items of the library', () {
      final songs = JellyfinSourceAdapter.parseItems(
        _jellyfinAnswer(),
        sourceId: 'jellyfin',
        server: _server,
        token: 'token-1',
      );

      expect(songs, hasLength(1));

      final song = songs.single;
      expect(song.title, 'Track name');
      expect(song.artist, 'Artist');
      expect(song.album, 'Album');
      expect(song.duration, 21000);
      expect(song.streamUrl, '$_server/Audio/123/stream?static=true');
      expect(
        song.artworkUrl,
        '$_server/Items/123/Images/Primary?api_key=token-1',
      );
      expect(song.genre, 'Rock');
      expect(song.genres, ['Rock']);
      expect(song.year, 1999);
      expect(song.bitrate, 320);
      expect(song.sampleRate, 44);
      expect(song.trackNumber, 3);
      expect(song.discNumber, 1);
      expect(song.size, 12345678);
      expect(song.httpHeaders?['X-Emby-Token'], 'token-1');
      expect(song.sourceId, 'jellyfin');
    });

    test('counts the length in ticks of a hundred nanoseconds', () {
      expect(JellyfinSourceAdapter.durationFromTicks(210000000), 21000);
      expect(JellyfinSourceAdapter.durationFromTicks(0), 0);
      expect(JellyfinSourceAdapter.durationFromTicks(null), 0);
    });

    test('converts the bitrate of the server into kilobit', () {
      final answer = _jellyfinAnswer();
      final item = (answer['Items'] as List).first as Map<String, dynamic>;
      item.remove('Bitrate');
      item.remove('SampleRate');

      final song = JellyfinSourceAdapter.parseItems(
        answer,
        sourceId: 'jellyfin',
        server: _server,
      ).single;

      expect(song.bitrate, 900);
      expect(song.sampleRate, 48);
    });

    test('falls back to the artists and to the year of the production', () {
      final answer = _jellyfinAnswer();
      final item = (answer['Items'] as List).first as Map<String, dynamic>;
      item.remove('AlbumArtist');
      item.remove('Year');
      item['ProductionYear'] = 2005;

      final song = JellyfinSourceAdapter.parseItems(
        answer,
        sourceId: 'jellyfin',
        server: _server,
      ).single;

      expect(song.artist, 'A');
      expect(song.year, 2005);
    });

    test('uses the defaults of a thin item', () {
      final answer = {
        'Items': [
          {'Id': '7', 'Name': 'Bare track'},
        ],
      };

      final song = JellyfinSourceAdapter.parseItems(
        answer,
        sourceId: 'jellyfin',
        server: _server,
      ).single;

      expect(song.title, 'Bare track');
      expect(song.artist, '');
      expect(song.album, '');
      expect(song.duration, 0);
      expect(song.genre, isNull);
      expect(song.genres, isNull);
      expect(song.year, isNull);
      expect(song.bitrate, isNull);
      expect(song.sampleRate, isNull);
      expect(song.trackNumber, isNull);
      expect(song.discNumber, isNull);
      expect(song.size, isNull);
      expect(song.streamUrl, '$_server/Audio/7/stream?static=true');
      expect(song.httpHeaders, isNull);
    });

    test('keeps every item only once', () {
      final answer = _jellyfinAnswer();
      final items = answer['Items'] as List;
      items.add((items.first as Map<String, dynamic>));

      final songs = JellyfinSourceAdapter.parseItems(
        answer,
        sourceId: 'jellyfin',
        server: _server,
      );

      expect(songs, hasLength(1));
    });

    test('answers a broken answer with no track', () {
      expect(
        JellyfinSourceAdapter.parseItems(
          {},
          sourceId: 'jellyfin',
          server: _server,
        ),
        isEmpty,
      );
    });

    test('reads the token of a login', () {
      expect(JellyfinSourceAdapter.parseToken({'AccessToken': 'abc'}), 'abc');
      expect(JellyfinSourceAdapter.parseToken({'AccessToken': ' '}), isNull);
      expect(JellyfinSourceAdapter.parseToken({}), isNull);
      expect(JellyfinSourceAdapter.parseToken(null), isNull);
    });

    test('reads the lyrics of a track', () {
      expect(
        JellyfinSourceAdapter.parseLyrics({'Lyrics': ' line one\nline two '}),
        'line one\nline two',
      );
      expect(
        JellyfinSourceAdapter.parseLyrics({
          'Lyrics': [
            {'Text': 'first'},
            {'Text': 'second'},
          ],
        }),
        'first\nsecond',
      );
      expect(JellyfinSourceAdapter.parseLyrics({'Lyrics': ''}), isNull);
      expect(JellyfinSourceAdapter.parseLyrics(null), isNull);
    });

    test('normalizes the address of the server', () {
      expect(
        JellyfinSourceAdapter.normalizeServer('192.168.1.10:8096'),
        'http://192.168.1.10:8096',
      );
      expect(
        JellyfinSourceAdapter.normalizeServer('http://localhost:8096/'),
        'http://localhost:8096',
      );
      expect(
        JellyfinSourceAdapter.normalizeServer('https://media.example.com/jf/'),
        'https://media.example.com/jf',
      );
      expect(JellyfinSourceAdapter.normalizeServer(' '), isNull);
      expect(JellyfinSourceAdapter.normalizeServer(null), isNull);
    });
  });
}

const _commonsFile =
    'https://upload.wikimedia.org/wikipedia/commons/0/03/Jazz_at_the_park.ogg';

const _server = 'http://localhost:8096';

/// The answer of the Commons API for one audio file.
Map<String, dynamic> _commonsAnswer() {
  return {
    'query': {
      'pages': {
        '172622974': _pageWith({
          'url': '$_commonsFile?utm_source=commons.wikimedia.org',
          'descriptionurl':
              'https://commons.wikimedia.org/wiki/File:Jazz_at_the_park.ogg',
          'size': 2088081,
          'duration': 205.72114583333334,
          'mime': 'application/ogg',
          'mediatype': 'AUDIO',
          'extmetadata': {
            'ObjectName': 'Jazz at the park',
            'Artist':
                '<a href="https://commons.wikimedia.org/wiki/User:Example">'
                'Man with a metal pig</a>',
            'ImageDescription': 'Flute and Tenor Sax Jazz duo at a public park',
            'LicenseShortName': 'CC0',
            'UsageTerms': 'Creative Commons Zero, Public Domain Dedication',
            'DateTimeOriginal': '2025-08-12',
            'Categories':
                'CC-Zero|Self-published work|Audio files of jazz music',
          },
        }),
      },
    },
  };
}

/// The image information of the file of the answer.
Map<String, dynamic> _imageInfo(Map<String, dynamic> answer) {
  final pages = answer['query']['pages'] as Map<String, dynamic>;
  final page = pages['172622974'] as Map<String, dynamic>;
  final infos = page['imageinfo'] as List;
  return infos.first as Map<String, dynamic>;
}

/// One page of the Commons answer.
Map<String, dynamic> _pageWith(
  Map<String, dynamic> imageInfo, {
  String title = 'File:Jazz at the park.ogg',
}) {
  return {
    'title': title,
    'imageinfo': [imageInfo],
  };
}

/// The answer of the Jellyfin API for one track.
Map<String, dynamic> _jellyfinAnswer() {
  return {
    'Items': [
      {
        'Id': '123',
        'Name': 'Track name',
        'Album': 'Album',
        'AlbumArtist': 'Artist',
        'Artists': ['A', 'B'],
        'RunTimeTicks': 210000000,
        'Bitrate': 320000,
        'SampleRate': 44100,
        'Year': 1999,
        'Genres': ['Rock'],
        'IndexNumber': 3,
        'ParentIndexNumber': 1,
        'MediaSources': [
          {
            'Id': 'ms-1',
            'Path': '/music/a.flac',
            'Container': 'flac',
            'Bitrate': 900000,
            'SampleRate': 48000,
            'Size': 12345678,
          },
        ],
      },
    ],
  };
}
