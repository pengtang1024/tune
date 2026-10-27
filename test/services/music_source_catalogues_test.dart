import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/audius_source.dart';
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

/// A Dio that answers with an empty station list and keeps the requests.
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
