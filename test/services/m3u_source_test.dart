import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/m3u_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';

/// The reader brings a playlist along and the entries become tracks.
///
/// The playlist is written by hand, so the reading of it is the whole type:
/// the comments are dropped, a relative path points into the folder of the
/// playlist, and the same address twice is one track.
void main() {
  group('the entries of a playlist', () {
    test('the lines of an m3u, without the comments', () {
      const body = '''
#EXTM3U
#EXTINF:123,Night Drive
https://example.com/one.mp3
#EXTINF:456,Second
https://example.com/two.mp3
''';

      expect(M3uSourceAdapter.parseEntries(body), [
        'https://example.com/one.mp3',
        'https://example.com/two.mp3',
      ]);
    });

    test('the File lines of a pls, without the rest', () {
      const body = '''
[playlist]
NumberOfEntries=2
File1=https://example.com/one.mp3
Title1=Night Drive
Length1=-1
File2=https://example.com/two.mp3
''';

      expect(M3uSourceAdapter.parseEntries(body), [
        'https://example.com/one.mp3',
        'https://example.com/two.mp3',
      ]);
    });

    test('an empty playlist has no entries', () {
      expect(M3uSourceAdapter.parseEntries('\n\n'), isEmpty);
    });
  });

  group('the address of an entry', () {
    test('a relative path points into the folder of the playlist', () {
      expect(
        M3uSourceAdapter.resolveEntry(
          'music/one.mp3',
          'https://example.com/list/list.m3u',
        ),
        'https://example.com/list/music/one.mp3',
      );
    });

    test('an address is kept as it is', () {
      expect(
        M3uSourceAdapter.resolveEntry(
          'https://other.test/one.mp3',
          'https://example.com/list/list.m3u',
        ),
        'https://other.test/one.mp3',
      );
    });

    test('a path that names nothing playable is dropped', () {
      expect(
        M3uSourceAdapter.resolveEntry(
          'C:\\music\\one.mp3',
          'https://example.com/list/list.m3u',
        ),
        isNull,
      );
    });
  });

  group('the tracks of a playlist', () {
    test('every entry becomes a track, named after its file', () {
      final songs = M3uSourceAdapter.parsePlaylist(
        '''
https://example.com/music/Night%20Drive.mp3
music/Second.mp3
''',
        sourceId: 'm3u-1',
        playlistUrl: 'https://example.com/list/list.m3u',
      );

      expect(songs.map((song) => song.title), ['Night Drive', 'Second']);
      expect(songs.first.streamUrl, 'https://example.com/music/Night%20Drive.mp3');
      expect(songs.last.streamUrl, 'https://example.com/list/music/Second.mp3');
      expect(songs.first.sourceId, 'm3u-1');
    });

    test('the same address twice is one track', () {
      final songs = M3uSourceAdapter.parsePlaylist(
        '''
https://example.com/one.mp3
https://example.com/one.mp3
''',
        sourceId: 'm3u-1',
        playlistUrl: 'https://example.com/list.m3u',
      );

      expect(songs, hasLength(1));
    });
  });

  group('the scan of a playlist', () {
    test('the entries of the playlist come back as tracks', () async {
      final adapter = _PlaylistAdapter(
        'https://example.com/one.mp3\nhttps://example.com/two.mp3\n',
      );
      final dio = Dio(BaseOptions(responseType: ResponseType.plain))
        ..httpClientAdapter = adapter;

      final result = await M3uSourceAdapter(dio: dio).scan(
        MusicSourceScanRequest(
          config: const MusicSourceConfig(
            id: 'm3u-1',
            type: 'm3u',
            name: '播放列表',
            kind: MusicSourceKind.custom,
            settings: {'playlist': 'https://example.com/list.m3u'},
          ),
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.songs, hasLength(2));
      expect(adapter.requested, ['https://example.com/list.m3u']);
    });

    test('a playlist without an address asks for one', () async {
      final result = await M3uSourceAdapter(dio: Dio()).scan(
        MusicSourceScanRequest(
          config: const MusicSourceConfig(
            id: 'm3u-1',
            type: 'm3u',
            name: '播放列表',
            kind: MusicSourceKind.custom,
          ),
        ),
      );

      expect(result.status.name, 'needsConfiguration');
      expect(result.songs, isEmpty);
    });

    test('an empty playlist is a failure', () async {
      final dio = Dio(BaseOptions(responseType: ResponseType.plain))
        ..httpClientAdapter = _PlaylistAdapter('   \n');

      final result = await M3uSourceAdapter(dio: dio).scan(
        MusicSourceScanRequest(
          config: const MusicSourceConfig(
            id: 'm3u-1',
            type: 'm3u',
            name: '播放列表',
            kind: MusicSourceKind.custom,
            settings: {'playlist': 'https://example.com/list.m3u'},
          ),
        ),
      );

      expect(result.status.name, 'failed');
      expect(result.message, isNotNull);
    });
  });
}

/// Answers every request with the same body.
class _PlaylistAdapter implements HttpClientAdapter {
  _PlaylistAdapter(this.body);

  final String body;

  /// The addresses that were requested.
  final List<String> requested = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options.uri.toString());

    final bytes = Uint8List.fromList(utf8.encode(body));
    return ResponseBody(
      Stream<Uint8List>.value(bytes),
      200,
      headers: {
        Headers.contentLengthHeader: [bytes.length.toString()],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
