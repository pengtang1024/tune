import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/ccmixter_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/podcast_rss_source.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Tests that talk to the public APIs of the new sources.
///
/// They prove that the sources work against the real services and not only
/// against a mock. The tests are skipped on a machine without internet.
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The test binding replaces the HTTP client with a mock that answers every
  // request with an error. The live tests need the real network.
  HttpOverrides.global = null;

  final online = await _isOnline();
  const offline = 'This machine has no internet connection.';

  group('ccMixter', () {
    test(
      'delivers tracks whose audio can be downloaded',
      () async {
        final result = await CcMixterSourceAdapter().scan(
          _request('ccmixter', {'query': 'jazz'}),
        );

        expect(result.status, SourceScanStatus.success);
        expect(result.songs, isNotEmpty);

        final song = result.songs.first;
        expect(song.title, isNotEmpty);
        expect(song.artist, isNotEmpty);
        expect(song.streamUrl, startsWith('https://'));
        expect(song.duration, greaterThan(0));

        await _expectPlayable(song);
      },
      skip: online ? false : offline,
      timeout: const Timeout(Duration(seconds: 90)),
    );
  });

  group('podcast RSS', () {
    test(
      'delivers episodes whose audio can be downloaded',
      () async {
        final result = await PodcastRssSourceAdapter().scan(
          _request('podcast_rss', {
            'feed': 'https://feeds.npr.org/510289/podcast.xml',
          }),
        );

        expect(result.status, SourceScanStatus.success);
        expect(result.songs, isNotEmpty);

        final song = result.songs.first;
        expect(song.title, isNotEmpty);
        expect(song.album, isNotEmpty);
        expect(song.streamUrl, startsWith('https://'));
        expect(song.duration, greaterThan(0));

        await _expectPlayable(song);
      },
      skip: online ? false : offline,
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });
}

MusicSourceScanRequest _request(String sourceId, Map<String, String> settings) {
  return MusicSourceScanRequest(
    config: MusicSourceConfig(
      id: sourceId,
      name: sourceId,
      kind: MusicSourceKind.openCatalog,
      settings: settings,
    ),
  );
}

/// Downloads the first bytes of a track to prove that it can be played.
Future<void> _expectPlayable(Song song) async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: true,
      headers: song.httpHeaders,
    ),
  );
  addTearDown(() => dio.close(force: true));

  final response = await dio.get<List<int>>(
    song.playbackUri,
    options: Options(
      responseType: ResponseType.bytes,
      headers: {...?song.httpHeaders, 'Range': 'bytes=0-2047'},
    ),
  );

  expect(response.statusCode, anyOf(200, 206));
  expect(response.data, isNotEmpty);
}

/// Checks whether the machine can reach the internet.
Future<bool> _isOnline() async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );
  try {
    final response = await dio.get<String>(
      'https://itunes.apple.com/search',
      queryParameters: {'term': 'tune', 'media': 'music', 'limit': 1},
      options: Options(responseType: ResponseType.plain),
    );
    return response.statusCode == 200;
  } catch (_) {
    return false;
  } finally {
    dio.close(force: true);
  }
}
