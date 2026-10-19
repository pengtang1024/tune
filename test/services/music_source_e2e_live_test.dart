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
          .where((config) => const {'ccmixter', 'itunes'}.contains(config.id))
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
