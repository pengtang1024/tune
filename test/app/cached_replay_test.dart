import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/audio_source_address.dart';
import 'package:tune/data/services/impl/http_song_download_service_io.dart';
import 'package:tune/data/services/impl/library_paths_io.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/audio_source_resolver.dart';
import 'package:tune/features/player/domain/audio_source_status.dart';

import '../services/fake_artwork_cache.dart';
import '../services/fake_http_adapter.dart';
import '../services/fake_persistence.dart';

/// A track that was fetched can be played again.
///
/// The copy lives in the music library, and the address the backend loads is
/// a file address. Both halves have to hold, or the track cannot be replayed.
void main() {
  late Directory library;
  late HttpSongDownloadService service;
  late AudioSourceResolver resolver;

  const song = Song(
    id: 1,
    title: 'Two',
    artist: 'Artist',
    uri: 'tune://openverse/two',
    streamUrl: 'https://cdn.test/two.mp3',
  );

  setUp(() async {
    library = await Directory.systemTemp.createTemp('tune_replay');
    final persistence = FakePersistenceService()
      ..values[LibraryPaths.rootKey] = library.path;
    service = HttpSongDownloadService(
      client: Dio()..httpClientAdapter = FakeHttpAdapter(),
      paths: FileLibraryPaths(persistence),
      artwork: FakeArtworkCache(),
    );
    resolver = AudioSourceResolver(service);
  });

  tearDown(() async {
    service.dispose();
    if (library.existsSync()) {
      await library.delete(recursive: true);
    }
  });

  test(
    'a fetched track is played again from the copy in the library',
    () async {
      final first = await resolver.sourceFor(song);
      expect(first.status, AudioSourceStatus.caching);

      await service.download(song);

      final second = await resolver.sourceFor(song);
      expect(second.status, AudioSourceStatus.cached);
      expect(second.file, path.join(library.path, 'Artist', 'Two', 'Two.mp3'));

      final address = audioSourceAddress(song, second.file!, fromStore: true);
      expect(address.scheme, 'file');
      expect(address.path, endsWith('/Artist/Two/Two.mp3'));
    },
  );

  test('a track that knows its copy plays from that copy', () async {
    // A track that was fetched and scanned again carries the file it was
    // written to, so the playback reads that file and asks nobody.
    final file = File(path.join(library.path, 'Artist', 'Two', 'Two.mp3'))
      ..createSync(recursive: true);

    final source = await resolver.sourceFor(song.copyWith(localPath: file.path));

    expect(source.status, AudioSourceStatus.cached);
    expect(source.file, file.path);
  });
}
