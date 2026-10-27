import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/lrclib_lyrics_provider.dart';
import 'package:tune/data/services/music_sources/lyrics_provider.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/music_sources/subsonic_source.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

import 'fake_persistence.dart';

void main() {
  group('LRCLIB provider', () {
    test('prefers a sheet with time stamps of the same length', () {
      final picked = LrclibLyricsProvider.pickLyrics([
        {
          'duration': 400,
          'plainLyrics': 'plain of another length',
          'syncedLyrics': '[00:10] synced of another length',
        },
        {
          'duration': 100,
          'plainLyrics': 'plain of the same length',
          'syncedLyrics': '[00:10] synced of the same length',
        },
      ], 100000);

      expect(picked, '[00:10] synced of the same length');
    });

    test('prefers the plain text of the same length over a foreign sheet', () {
      final picked = LrclibLyricsProvider.pickLyrics([
        {'duration': 400, 'syncedLyrics': '[00:10] synced of another length'},
        {'duration': 100, 'plainLyrics': 'plain of the same length'},
      ], 100000);

      expect(picked, 'plain of the same length');
    });

    test('falls back to a sheet of another length', () {
      final picked = LrclibLyricsProvider.pickLyrics([
        {
          'duration': 400,
          'plainLyrics': 'plain of another length',
          'syncedLyrics': '[00:10] synced of another length',
        },
      ], 100000);

      expect(picked, '[00:10] synced of another length');
    });

    test('another master of the song counts as the same length', () {
      final picked = LrclibLyricsProvider.pickLyrics([
        {
          'duration': 210,
          'syncedLyrics': '[00:10] synced of another master',
        },
        {
          'duration': 203.5,
          'plainLyrics': 'plain of nearly the same length',
        },
      ], 200000);

      expect(picked, 'plain of nearly the same length');
    });

    test('ignores an empty text', () {
      final picked = LrclibLyricsProvider.pickLyrics([
        {'duration': 100, 'plainLyrics': '   ', 'syncedLyrics': ''},
      ], 100000);

      expect(picked, isNull);
    });

    test('answers an empty answer with no sheet', () {
      expect(LrclibLyricsProvider.pickLyrics(const [], 100000), isNull);
      expect(LrclibLyricsProvider.pickLyrics(['not a map'], 100000), isNull);
    });
  });

  group('Subsonic lyrics', () {
    test('reads the text of the track', () {
      final lyrics = SubsonicSourceAdapter.parseLyrics({
        'lyrics': {
          'song': {'value': '  first line\nsecond line  '},
        },
      });

      expect(lyrics, 'first line\nsecond line');
    });

    test('answers an empty answer with no text', () {
      expect(SubsonicSourceAdapter.parseLyrics(const {}), isNull);
      expect(
        SubsonicSourceAdapter.parseLyrics({
          'lyrics': {
            'song': {'value': ' '},
          },
        }),
        isNull,
      );
    });
  });

  group('the LRCLIB provider asks', () {
    test('the exact match comes first', () async {
      final http = _LyricsHttp()
        ..answer('/api/get', {
          'syncedLyrics': '[00:10] exact',
          'duration': 120,
        })
        ..answer('/api/search', const []);
      final provider = LrclibLyricsProvider(dio: http.dio);

      final lyrics = await provider.lookup(_song());

      expect(http.requested.first, contains('/api/get'));
      expect(lyrics, '[00:10] exact');
    });

    test('the search is used when the exact match does not answer', () async {
      final http = _LyricsHttp()
        ..answer('/api/search', [
          {'syncedLyrics': '[00:10] searched', 'duration': 120},
        ]);
      final provider = LrclibLyricsProvider(dio: http.dio);

      final lyrics = await provider.lookup(_song());

      expect(lyrics, '[00:10] searched');
      expect(http.requested, hasLength(2));
    });

    test('the plain text of an exact match is used too', () async {
      final http = _LyricsHttp()
        ..answer('/api/get', {
          'plainLyrics': 'plain of the exact match',
          'duration': 120,
        });
      final provider = LrclibLyricsProvider(dio: http.dio);

      final lyrics = await provider.lookup(_song());

      expect(lyrics, 'plain of the exact match');
    });

    test('the artist is shortened when nothing is found', () async {
      final http = _LyricsHttp()
        ..answer('/api/search', const [], whenArtist: 'Miles Davis feat. Kim')
        ..answer('/api/search', [
          {'syncedLyrics': '[00:10] short', 'duration': 120},
        ], whenArtist: 'Miles Davis');
      final provider = LrclibLyricsProvider(dio: http.dio);

      final lyrics = await provider.lookup(
        _song(artist: 'Miles Davis feat. Kim'),
      );

      expect(lyrics, '[00:10] short');
    });

    test('a track without a title is not asked about', () async {
      final http = _LyricsHttp();
      final provider = LrclibLyricsProvider(dio: http.dio);

      expect(await provider.lookup(_song(title: ' ')), isNull);
      expect(http.requested, isEmpty);
    });

    test('the name of the artist is shortened', () {
      expect(
        LrclibLyricsProvider.shortenArtist('Miles Davis feat. John Coltrane'),
        'Miles Davis',
      );
      expect(
        LrclibLyricsProvider.shortenArtist('Miles Davis (Remastered 2011)'),
        'Miles Davis',
      );
      expect(LrclibLyricsProvider.shortenArtist('Billy Withers'), 'Billy Withers');
      expect(LrclibLyricsProvider.shortenArtist('AC/DC'), 'AC/DC');
    });
  });

  group('lyrics of the service', () {
    test('a track that carries lyrics keeps them', () async {
      final provider = _RecordingLyricsProvider('from the database');
      final service = _service(provider);

      final lyrics = await service.fetchLyrics(
        const Song(
          id: 1,
          title: 'Night Drive',
          artist: 'Nova',
          uri: 'tune://openverse/1',
          sourceId: 'openverse',
          externalId: '1',
          lyrics: 'already there',
        ),
      );

      expect(lyrics, 'already there');
      expect(provider.asked, isEmpty);
    });

    test('a source without lyrics falls back to the database', () async {
      final provider = _RecordingLyricsProvider('from the database');
      final service = _service(provider);

      final lyrics = await service.fetchLyrics(
        const Song(
          id: 2,
          title: 'Night Drive',
          artist: 'Nova',
          uri: 'tune://openverse/2',
          sourceId: 'openverse',
          externalId: '2',
        ),
      );

      expect(lyrics, 'from the database');
      expect(provider.asked, hasLength(1));
      expect(provider.asked.single.title, 'Night Drive');
    });

    test('a track without a source falls back to the database', () async {
      final provider = _RecordingLyricsProvider('from the database');
      final service = _service(provider);

      final lyrics = await service.fetchLyrics(
        const Song(
          id: 3,
          title: 'Night Drive',
          artist: 'Nova',
          uri: '/music/local.mp3',
        ),
      );

      expect(lyrics, 'from the database');
      expect(provider.asked, hasLength(1));
      expect(provider.asked.single.title, 'Night Drive');
    });

    test('a source that fails does not stop the database', () async {
      final provider = _RecordingLyricsProvider('from the database');
      final service = _service(
        provider,
        adapters: {'openverse': _FailingSource()},
      );

      final lyrics = await service.fetchLyrics(
        const Song(
          id: 4,
          title: 'Night Drive',
          artist: 'Nova',
          uri: 'tune://openverse/4',
          sourceId: 'openverse',
          externalId: '4',
        ),
      );

      expect(lyrics, 'from the database');
      expect(provider.asked, hasLength(1));
    });

    test('the failure of the database reaches the caller', () async {
      final service = _service(_FailingDatabase());

      expect(
        () => service.fetchLyrics(
          const Song(
            id: 5,
            title: 'Night Drive',
            artist: 'Nova',
            uri: 'tune://openverse/5',
            sourceId: 'openverse',
            externalId: '5',
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

/// The service under test, backed by an in-memory store.
MusicSourceService _service(
  LyricsProvider provider, {
  Map<String, MusicSourceAdapter>? adapters,
}) {
  return MusicSourceService(
    scanner: CrossPlatformMusicScannerImpl(),
    store: MusicSourceStore(FakePersistenceService()),
    lyricsProvider: provider,
    adapters: adapters,
  );
}

/// A lyrics database that answers with the same text every time.
class _RecordingLyricsProvider implements LyricsProvider {
  final String answer;

  /// The tracks the provider was asked about.
  final List<Song> asked = [];

  _RecordingLyricsProvider(this.answer);

  @override
  Future<String?> lookup(Song song) async {
    asked.add(song);
    return answer;
  }
}

/// A lyrics database that cannot answer.
class _FailingDatabase implements LyricsProvider {
  @override
  Future<String?> lookup(Song song) async {
    throw StateError('the database is not reachable');
  }
}

/// A source whose lyrics cannot be read.
class _FailingSource extends MusicSourceAdapter {
  @override
  String get sourceType => 'openverse';

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  String get configurationHint => '';

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    return SourceScanResult(
      sourceId: request.config.id,
      status: SourceScanStatus.success,
    );
  }

  @override
  Future<String?> fetchLyrics(MusicSourceConfig config, Song song) async {
    throw StateError('the source is not reachable');
  }
}

/// The track the lyrics are asked about.
Song _song({
  String title = 'So What',
  String artist = 'Miles Davis',
  int duration = 120000,
}) {
  return Song(
    id: 1,
    title: title,
    artist: artist,
    album: 'Kind of Blue',
    uri: 'tune://openverse/1',
    duration: duration,
  );
}

/// One answer of the lyrics database.
class _Answer {
  const _Answer(this.path, this.body, this.whenArtist);

  final String path;
  final Object? body;
  final String? whenArtist;
}

/// The lyrics database, answered by the test.
class _LyricsHttp implements HttpClientAdapter {
  /// The addresses that were requested.
  final List<String> requested = [];

  final List<_Answer> _answers = [];

  /// The client the provider asks.
  Dio get dio {
    final client = Dio();
    client.httpClientAdapter = this;
    return client;
  }

  /// Sets the answer of a path.
  void answer(String path, Object? body, {String? whenArtist}) {
    _answers.add(_Answer(path, body, whenArtist));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options.uri.toString());

    final artist = options.uri.queryParameters['artist_name'];
    for (final answer in _answers) {
      if (answer.path != options.uri.path) continue;
      if (answer.whenArtist != null && answer.whenArtist != artist) continue;
      return _body(answer.body);
    }
    return _body(null, status: 404);
  }

  @override
  void close({bool force = false}) {}

  ResponseBody _body(Object? body, {int status = 200}) {
    final bytes = body == null
        ? Uint8List(0)
        : Uint8List.fromList(utf8.encode(jsonEncode(body)));
    return ResponseBody(
      Stream<Uint8List>.value(bytes),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        Headers.contentLengthHeader: [bytes.length.toString()],
      },
    );
  }
}
