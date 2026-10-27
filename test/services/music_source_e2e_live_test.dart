import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

import 'fake_persistence.dart';

/// End-to-end check of the whole chain the app uses:
/// built-in config -> MusicSourceService -> adapter registry -> real API -> Song.
///
/// The other live test calls the adapters directly, so it would still pass if
/// a new source was never registered in the service.
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  final online = await _isOnline();
  const offline = 'This machine has no internet connection.';

  test(
    'the service scans the new built-in sources through the real network',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      // The configs the app ships with, not hand-made ones.
      final sources = BuiltInMusicSources.defaults
          .where((config) => const {'ccmixter', 'audius'}.contains(config.id))
          .map(
            (config) => config.copyWith(
              settings: {...config.settings, 'query': 'jazz'},
            ),
          )
          .toList();

      expect(sources, hasLength(2));

      final results = await service.search(sources: sources, query: 'jazz');

      expect(results, hasLength(2));
      for (final result in results) {
        expect(
          result.status,
          SourceScanStatus.success,
          reason: '${result.sourceId} failed: ${result.message}',
        );
        expect(
          result.songs,
          isNotEmpty,
          reason: '${result.sourceId} returned nothing',
        );

        final song = result.songs.first;
        expect(song.sourceId, result.sourceId);
        expect(song.title, isNotEmpty);
        expect(song.artist, isNotEmpty);
        expect(song.streamUrl, startsWith('https://'));
        expect(song.uri, startsWith('tune://${result.sourceId}/'));
      }
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'the service scans LibriVox into whole chapters',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      // The built-in configuration of LibriVox: no keyword, no limits set.
      // A scan without a keyword reads the books everybody listens to.
      final result = (await service.scanAll(
        sources: BuiltInMusicSources.defaults
            .where((config) => config.id == 'librivox')
            .toList(),
        localPaths: const [],
      )).single;

      expect(
        result.status,
        SourceScanStatus.success,
        reason: 'LibriVox failed: ${result.message}',
      );
      expect(result.songs, isNotEmpty, reason: 'LibriVox returned nothing');

      // One book is fetched for each of its chapters, so every chapter of
      // the scan carries the album of the book it belongs to.
      final albums = result.songs.map((song) => song.album).toSet();
      expect(albums.where((album) => album.isEmpty), isEmpty);
      expect(result.songs.first.trackNumber, isNotNull);
      expect(result.songs.first.streamUrl, startsWith('https://'));
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 180)),
  );

  test(
    'the radio source reads the stations of any country',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );
      final radio = BuiltInMusicSources.radio;

      for (final country in const ['SG', 'MY', 'AU']) {
        final result = (await service.scanAll(
          sources: [
            radio.copyWith(
              settings: {
                'provider': 'browser',
                'country': country,
                'query': '',
              },
            ),
          ],
          localPaths: const [],
        )).single;

        expect(
          result.status,
          SourceScanStatus.success,
          reason: '\$country failed: \${result.message}',
        );
        expect(result.songs, isNotEmpty, reason: '\$country returned nothing');
      }
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'the service reads the podcast directory',
    () async {
      final service = MusicSourceService(
        scanner: _NoopScanner(),
        store: MusicSourceStore(FakePersistenceService()),
      );

      final result = (await service.search(
        sources: BuiltInMusicSources.defaults
            .where((config) => config.id == 'podcast_catalog')
            .toList(),
        query: 'jazz',
      )).single;

      expect(
        result.status,
        SourceScanStatus.success,
        reason: 'Podcast directory failed: ${result.message}',
      );
      expect(
        result.songs,
        isNotEmpty,
        reason: 'Podcast directory returned nothing: ${result.message}',
      );

      final song = result.songs.first;
      expect(song.album, isNotEmpty);
      expect(song.streamUrl, startsWith('http'));
      expect(song.title, isNotEmpty);
    },
    skip: online ? false : offline,
    timeout: const Timeout(Duration(seconds: 180)),
  );
}

class _NoopScanner extends CrossPlatformMusicScannerImpl {
  @override
  Future<List<Song>> scanMusicInDirectoriesWithProgress(
    List<String> directoryPaths,
    Function(double) onProgress,
  ) async => const [];
}

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
