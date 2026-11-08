import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/audius_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/data/services/music_sources/radio_source.dart';
import 'package:tune/data/services/music_sources/radio_station.dart';
import 'package:tune/data/services/music_sources/radio_station_providers.dart';

void main() {
  group('Audius adapter', () {
    test('maps the tracks of the search answer', () {
      final songs = AudiusSourceAdapter.parseResults(
        _audiusAnswer(),
        sourceId: 'audius',
      );

      expect(songs, hasLength(1));

      final song = songs.single;
      expect(song.title, 'Night Drive');
      expect(song.artist, 'Nova');
      expect(song.album, 'City Lights');
      expect(song.duration, 214000);
      expect(song.streamUrl, contains('/v1/tracks/trk-1/stream'));
      expect(song.artworkUrl, 'https://cdn.example.com/1000x1000.jpg');
      expect(song.genre, 'Electronic');
      expect(song.genres, ['electronic', 'ambient']);
      expect(song.year, 2021);
      expect(song.license, 'CC0');
      expect(song.description, 'A track recorded at night.');
      expect(song.sourceId, 'audius');
      expect(song.uri, 'tune://audius/trk-1');
    });

    test('keeps every track only once', () {
      final answer = _audiusAnswer();
      final data = answer['data'] as List;
      data.add(data.first);

      final songs = AudiusSourceAdapter.parseResults(
        answer,
        sourceId: 'audius',
      );

      expect(songs, hasLength(1));
    });

    test('skips a track without a title', () {
      final answer = _audiusAnswer();
      (answer['data'] as List).first['title'] = '   ';

      expect(
        AudiusSourceAdapter.parseResults(answer, sourceId: 'audius'),
        isEmpty,
      );
    });

    test('hides a licence that reserves every right', () {
      final answer = _audiusAnswer();
      (answer['data'] as List).first['license'] = 'All rights reserved';

      final song = AudiusSourceAdapter.parseResults(
        answer,
        sourceId: 'audius',
      ).single;

      expect(song.license, isNull);
    });

    test('keeps the limit of the scan', () {
      final answer = _audiusAnswer();
      (answer['data'] as List).add({
        'id': 'trk-2',
        'title': 'Second track',
        'duration': 100,
      });

      final songs = AudiusSourceAdapter.parseResults(
        answer,
        sourceId: 'audius',
        limit: 1,
      );

      expect(songs, hasLength(1));
      expect(songs.single.externalId, 'trk-1');
    });

    test('answers an empty response with no track', () {
      expect(AudiusSourceAdapter.parseResults({}, sourceId: 'audius'), isEmpty);
    });
  });

  group('Audius reaches', () {
    test('a reach and a window are sent to the trending list', () async {
      final captured = _CapturedLive(const {'data': <dynamic>[]});
      final provider = AudiusSourceAdapter(dio: captured.dio);

      await provider.scan(
        _audiusRequest(const {'genre': 'Jazz', 'window': 'week'}),
      );

      final uri = captured.uris.single;
      expect(uri.path, '/v1/tracks/trending');
      expect(uri.queryParameters['genre'], 'Jazz');
      expect(uri.queryParameters['time'], 'week');
    });

    test('a scan without a reach asks for the whole list', () async {
      final captured = _CapturedLive(const {'data': <dynamic>[]});
      final provider = AudiusSourceAdapter(dio: captured.dio);

      await provider.scan(_audiusRequest(const {}));

      final uri = captured.uris.single;
      expect(uri.queryParameters.containsKey('genre'), isFalse);
      expect(uri.queryParameters.containsKey('time'), isFalse);
    });

    test('a keyword searches instead of walking the trending list', () async {
      final captured = _CapturedLive(const {'data': <dynamic>[]});
      final provider = AudiusSourceAdapter(dio: captured.dio);

      await provider.scan(
        _audiusRequest(const {'query': 'nova', 'genre': 'Jazz'}),
      );

      final uri = captured.uris.single;
      expect(uri.path, '/v1/tracks/search');
      expect(uri.queryParameters['query'], 'nova');
      // The search endpoint has no reach: the setting belongs to the list.
      expect(uri.queryParameters.containsKey('genre'), isFalse);
    });
  });

  group('Radio Browser directory', () {
    test('maps the stations of the answer', () {
      final stations = RadioBrowserProvider.parseStations(
        _radioBrowserAnswer(),
      );

      expect(stations, hasLength(1));

      final station = stations.single;
      expect(station.provider, 'browser');
      expect(station.id, 'station-1');
      expect(station.name, 'Jazz FM');
      expect(station.streamUrl, 'https://stream.example.com/jazz');
      expect(station.artworkUrl, 'https://cdn.example.com/jazz.png');
      expect(station.genre, 'jazz / soul');
      expect(station.language, 'english');
      expect(station.country, 'Germany');
      expect(station.codec, 'MP3');
      expect(station.bitrate, 128);
      expect(station.listeners, 420);
    });

    test('skips a station whose last check failed', () {
      final answer = _radioBrowserAnswer();
      (answer.first as Map)['lastcheckok'] = 0;

      expect(RadioBrowserProvider.parseStations(answer), isEmpty);
    });

    test('skips a station without a stream', () {
      final answer = _radioBrowserAnswer();
      (answer.first as Map)['url_resolved'] = '';

      expect(RadioBrowserProvider.parseStations(answer), isEmpty);
    });

    test('answers an empty answer with no station', () {
      expect(RadioBrowserProvider.parseStations(const []), isEmpty);
    });

    test('a country narrows the stations of the directory', () async {
      final captured = _CapturedStations();
      final provider = RadioBrowserProvider(dio: captured.dio);

      await provider.fetch(query: '', limit: 5, country: 'SG');

      expect(captured.uris.first.queryParameters['countrycode'], 'SG');
      expect(captured.uris.first.path, '/json/stations/search');
    });

    test('a tag reads a reach of the whole directory', () async {
      final captured = _CapturedStations();
      final provider = RadioBrowserProvider(dio: captured.dio);

      await provider.fetch(query: '', limit: 5, tag: 'Jazz');

      final uri = captured.uris.first;
      expect(uri.path, '/json/stations/search');
      expect(uri.queryParameters['tag'], 'jazz');
      expect(uri.queryParameters.containsKey('name'), isFalse);
    });

    test('a tag and a country narrow together', () async {
      final captured = _CapturedStations();
      final provider = RadioBrowserProvider(dio: captured.dio);

      await provider.fetch(query: '', limit: 5, country: 'SG', tag: 'jazz');

      final uri = captured.uris.first;
      expect(uri.queryParameters['tag'], 'jazz');
      expect(uri.queryParameters['countrycode'], 'SG');
    });

    test('a keyword searches by the tag parameter the directory reads', () async {
      final captured = _CapturedStations();
      final provider = RadioBrowserProvider(dio: captured.dio);

      await provider.fetch(query: 'jazz', limit: 5);

      // The directory ignores a tagname parameter and would answer with the
      // unfiltered list, so neither request may use it.
      for (final uri in captured.uris) {
        expect(uri.queryParameters.containsKey('tagname'), isFalse);
      }
      // One request searches the names, the other the tag.
      expect(
        captured.uris
            .where((uri) => uri.queryParameters['tag'] == 'jazz')
            .length,
        1,
      );
      expect(
        captured.uris
            .where((uri) => uri.queryParameters['name'] == 'jazz')
            .length,
        1,
      );
    });

    test('an unreachable mirror falls back to another one', () async {
      final captured = _FailoverStations();
      final provider = RadioBrowserProvider(dio: captured.dio);

      final stations = await provider.fetch(
        query: '',
        limit: 5,
        country: 'SG',
      );

      expect(stations, isEmpty);
      expect(
        captured.uris.map((uri) => uri.host),
        contains('de1.api.radio-browser.info'),
      );
    });
  });

  group('SomaFM directory', () {
    test('maps the channels of the answer', () {
      final stations = SomaFmProvider.parseChannels(_somaFmAnswer());

      expect(stations, hasLength(1));

      final station = stations.single;
      expect(station.provider, 'somafm');
      expect(station.id, 'groovesalad');
      expect(station.name, 'Groove Salad');
      expect(station.streamUrl, 'https://ice1.somafm.com/groovesalad-128-mp3');
      expect(station.genre, 'Ambient');
      expect(station.description, 'A nicely chilled plate of ambient beats.');
      expect(station.nowPlayingArtist, 'Biosphere');
      expect(station.nowPlayingTitle, 'Substrata 2');
      expect(station.listeners, 120);
    });

    test('keeps a title without an artist', () {
      final answer = _somaFmAnswer();
      (answer['channels'] as List).first['lastPlaying'] = 'Just A Title';

      final station = SomaFmProvider.parseChannels(answer).single;

      expect(station.nowPlayingArtist, isNull);
      expect(station.nowPlayingTitle, 'Just A Title');
    });

    test('answers an empty answer with no station', () {
      expect(SomaFmProvider.parseChannels(const {}), isEmpty);
    });
  });

  group('NTS directory', () {
    test('maps the live channels of the answer', () {
      final stations = NtsProvider.parseLive(_ntsAnswer());

      expect(stations, hasLength(2));

      final station = stations.first;
      expect(station.provider, 'nts');
      expect(station.id, '1');
      expect(station.name, 'NTS 1');
      expect(
        station.streamUrl,
        'https://stream-relay-geo.ntslive.net/stream',
      );
      expect(station.artworkUrl, 'https://cdn.example.com/nts1.jpg');
      expect(station.genre, 'Ambient / Jazz / Experimental');
      expect(station.description, 'Freeform radio from the NTS studio.');
      expect(station.nowPlayingArtist, 'Soup to Nuts');
      expect(station.country, 'United Kingdom');
      expect(station.codec, 'MP3');

      expect(stations.last.name, 'NTS 2');
      expect(stations.last.streamUrl, endsWith('/stream2'));
    });

    test('skips a channel whose stream is not known', () {
      final answer = _ntsAnswer();
      (answer['results'] as List).add({
        'channel_name': '3',
        'now': {
          'embeds': {
            'details': {'name': 'A channel without a stream'},
          },
        },
      });

      expect(NtsProvider.parseLive(answer), hasLength(2));
    });

    test('answers an empty answer with no station', () {
      expect(NtsProvider.parseLive(const {}), isEmpty);
    });

    test('a keyword narrows the shows on air', () async {
      final captured = _CapturedLive(_ntsAnswer());
      final provider = NtsProvider(dio: captured.dio);

      final stations = await provider.fetch(query: 'jazz', limit: 5);

      expect(captured.uris.single.path, '/api/v2/live');
      expect(stations, hasLength(1));
      expect(stations.single.name, 'NTS 1');
    });
  });

  group('Radio France directory', () {
    test('lists the channels of the network', () async {
      final provider = RadioFranceProvider();

      expect(provider.id, 'radiofrance');
      expect(provider.displayName, 'Radio France');

      final stations = await provider.fetch(query: '', limit: 100);

      expect(stations, hasLength(18));
      expect(stations.map((station) => station.id).toSet(), hasLength(18));

      final station = stations.first;
      expect(station.provider, 'radiofrance');
      expect(station.id, 'fip');
      expect(station.name, 'FIP');
      expect(station.streamUrl, 'https://icecast.radiofrance.fr/fip-midfi.mp3');
      expect(station.genre, 'eclectic');
      expect(station.language, 'French');
      expect(station.country, 'France');
      expect(station.codec, 'MP3');
      expect(station.homepage, 'https://www.radiofrance.fr/fip');

      for (final channel in stations) {
        expect(
          channel.streamUrl,
          startsWith('https://icecast.radiofrance.fr/'),
          reason: channel.id,
        );
        expect(channel.streamUrl, endsWith('-midfi.mp3'), reason: channel.id);
      }
    });

    test('a keyword narrows the channels by name and by reach', () async {
      final provider = RadioFranceProvider();

      final byName = await provider.fetch(query: 'baroque', limit: 100);
      expect(byName.single.name, 'France Musique Baroque');

      final byGenre = await provider.fetch(query: 'reggae', limit: 100);
      expect(byGenre.single.name, 'FIP Reggae');
    });

    test('a window after the first one skips what it saw', () async {
      final provider = RadioFranceProvider();

      final stations = await provider.fetch(query: '', limit: 6, offset: 12);

      expect(stations, hasLength(6));
      expect(stations.first.id, 'francemusique');
      expect(stations.last.id, 'mouv');
    });

    test('a scan of another country has nothing to take', () async {
      final provider = RadioFranceProvider();

      expect(await provider.fetch(query: '', limit: 100, country: 'GB'), isEmpty);

      final france = await provider.fetch(
        query: '',
        limit: 100,
        country: 'fr',
      );
      expect(france, hasLength(18));
    });
  });

  group('Radio source', () {
    test('turns a station into a live track', () {
      final songs = RadioSourceAdapter.buildSongs([
        const RadioStation(
          provider: 'browser',
          id: 'station-1',
          name: 'Jazz FM',
          streamUrl: 'https://stream.example.com/jazz',
          artworkUrl: 'https://cdn.example.com/jazz.png',
          genre: 'jazz',
          language: 'english',
          country: 'Germany',
          description: 'Jazz around the clock',
          nowPlayingArtist: 'Miles Davis',
          nowPlayingTitle: 'So What',
          nowPlayingYear: 1959,
          bitrate: 128,
          codec: 'MP3',
          listeners: 42,
          homepage: 'https://example.com',
        ),
      ], sourceId: 'radio');

      expect(songs, hasLength(1));

      final song = songs.single;
      expect(song.title, 'Jazz FM');
      expect(song.artist, 'Miles Davis');
      expect(song.album, 'So What');
      expect(song.streamUrl, 'https://stream.example.com/jazz');
      expect(song.genre, 'jazz');
      expect(song.language, 'english');
      expect(song.year, 1959);
      expect(song.description, 'Jazz around the clock');
      expect(song.isLiveStream, isTrue);
      expect(song.sourceId, 'radio');
      expect(song.uri, 'tune://radio/browser%2Fstation-1');
      expect(song.sourceData?['nowPlaying'], 'Miles Davis - So What');
      expect(song.sourceData?['codec'], 'MP3');
      expect(song.sourceData?['bitrate'], 128);
    });

    test('falls back to the country when nothing is on air', () {
      final songs = RadioSourceAdapter.buildSongs(const [
        RadioStation(
          provider: 'somafm',
          id: 'drone',
          name: 'Drone Zone',
          streamUrl: 'https://ice1.somafm.com/drone-128-mp3',
          country: 'Canada',
        ),
      ], sourceId: 'radio');

      final song = songs.single;
      expect(song.artist, 'Canada');
      expect(song.album, '');
      expect(song.sourceData?['nowPlaying'], '');
    });

    test('keeps every station only once', () {
      const station = RadioStation(
        provider: 'browser',
        id: 'station-1',
        name: 'Jazz FM',
        streamUrl: 'https://stream.example.com/jazz',
      );

      final songs = RadioSourceAdapter.buildSongs(const [
        station,
        station,
      ], sourceId: 'radio');

      expect(songs, hasLength(1));
    });
  });
}

/// The answer of the Audius search for one track.
Map<String, dynamic> _audiusAnswer() {
  return {
    'data': [
      {
        'id': 'trk-1',
        'title': 'Night Drive',
        'duration': 214,
        'genre': 'Electronic',
        'tags': 'electronic, ambient , ',
        'release_date': '2021-06-22T07:04:10Z',
        'license': 'CC0',
        'description': 'A track recorded at night.',
        'user': {'name': 'Nova'},
        'album_backlink': {'playlist_name': 'City Lights'},
        'artwork': {
          '150x150': 'https://cdn.example.com/150x150.jpg',
          '1000x1000': 'https://cdn.example.com/1000x1000.jpg',
        },
      },
    ],
  };
}

/// The answer of the Radio Browser search for one station.
List<dynamic> _radioBrowserAnswer() {
  return [
    {
      'stationuuid': 'station-1',
      'name': 'Jazz FM',
      'url_resolved': 'https://stream.example.com/jazz',
      'favicon': 'https://cdn.example.com/jazz.png',
      'tags': 'jazz,soul',
      'language': 'english',
      'country': 'Germany',
      'codec': 'MP3',
      'bitrate': 128,
      'clickcount': 420,
      'homepage': 'https://example.com',
      'lastcheckok': 1,
    },
  ];
}

/// The answer of the SomaFM channel list.
Map<String, dynamic> _somaFmAnswer() {
  return {
    'channels': [
      {
        'id': 'groovesalad',
        'title': 'Groove Salad',
        'genre': 'Ambient',
        'description': 'A nicely chilled plate of ambient beats.',
        'image': 'https://cdn.example.com/soma.png',
        'lastPlaying': 'Biosphere - Substrata 2',
        'listeners': 120,
      },
    ],
  };
}

/// The live answer of NTS for its two channels.
Map<String, dynamic> _ntsAnswer() {
  return {
    'results': [
      {
        'channel_name': '1',
        'now': {
          'broadcast_title': 'Soup to Nuts',
          'embeds': {
            'details': {
              'name': 'Soup to Nuts',
              'description': 'Freeform radio from the NTS studio.',
              'genres': [
                {'id': 1, 'value': 'Ambient'},
                {'id': 2, 'value': 'Jazz'},
                {'id': 3, 'value': 'Experimental'},
                {'id': 4, 'value': 'Soul'},
              ],
              'moods': [
                {'id': 1, 'value': 'Chilled'},
              ],
              'media': {
                'background_large': 'https://cdn.example.com/nts1.jpg',
              },
            },
          },
        },
      },
      {
        'channel_name': '2',
        'now': {
          'embeds': {
            'details': {
              'name': 'Rave Cave',
              'genres': [
                {'id': 1, 'value': 'Techno'},
              ],
            },
          },
        },
      },
    ],
  };
}

/// A Dio that answers with the live answer of NTS and keeps the requests.
class _CapturedLive {
  _CapturedLive(this.body);

  final Map<String, dynamic> body;
  final uris = <Uri>[];

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          uris.add(options.uri);
          handler.resolve(
            Response(
              requestOptions: options,
              data: body,
              statusCode: 200,
            ),
          );
        },
      ),
    );
    return client;
  }
}

/// A Dio that answers with an empty station list and keeps the requests.
/// A client whose aggregate mirror cannot be reached, as on a network that
/// resolves it to an address it cannot route to.
class _FailoverStations {
  final uris = <Uri>[];

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          uris.add(options.uri);
          if (options.uri.host == 'all.api.radio-browser.info') {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                message: 'unreachable',
              ),
            );
            return;
          }
          handler.resolve(
            Response(
              requestOptions: options,
              data: <dynamic>[],
              statusCode: 200,
            ),
          );
        },
      ),
    );
    return client;
  }
}

class _CapturedStations {
  final uris = <Uri>[];

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          uris.add(options.uri);
          handler.resolve(
            Response(
              requestOptions: options,
              data: <dynamic>[],
              statusCode: 200,
            ),
          );
        },
      ),
    );
    return client;
  }
}

MusicSourceScanRequest _audiusRequest(Map<String, String> settings) {
  return MusicSourceScanRequest(
    config: MusicSourceConfig(
      id: 'audius',
      type: 'audius',
      name: 'Audius',
      kind: MusicSourceKind.openCatalog,
      settings: settings,
    ),
  );
}
