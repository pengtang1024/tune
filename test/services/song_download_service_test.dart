import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/impl/http_song_download_service_io.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/impl/library_paths_io.dart';
import 'package:tune/domain/models/song.dart';

import 'fake_artwork_cache.dart';
import 'fake_http_adapter.dart';
import 'fake_persistence.dart';

void main() {
  late Directory store;
  late FakeHttpAdapter adapter;
  late HttpSongDownloadService service;

  const song = Song(
    id: 1,
    title: 'One',
    artist: 'Artist',
    uri: 'https://source.test/one',
    streamUrl: 'https://cdn.test/one.mp3',
  );

  /// A track of a real remote source: its own address names the track.
  const canonicalSong = Song(
    id: 2,
    title: 'Two',
    artist: 'Artist',
    uri: 'tune://openverse/two',
    streamUrl: 'https://cdn.test/two.mp3',
  );

  setUp(() async {
    store = await Directory.systemTemp.createTemp('tune-download-test');
    adapter = FakeHttpAdapter();
    final persistence = FakePersistenceService()
      ..values[LibraryPaths.rootKey] = store.path;
    service = HttpSongDownloadService(
      client: Dio()..httpClientAdapter = adapter,
      paths: FileLibraryPaths(persistence),
      artwork: FakeArtworkCache(),
    );
  });

  tearDown(() async {
    service.dispose();
    if (store.existsSync()) {
      await store.delete(recursive: true);
    }
  });

  test('the fetched track lands in the folder of the track', () async {
    final file = await service.download(song);

    expect(File(file).existsSync(), isTrue);
    expect(await service.storedFileFor(song), file);
    expect(
      file,
      path.join(store.path, 'Artist', 'One', 'One.mp3'),
    );
    expect(adapter.requestedUrls, ['https://cdn.test/one.mp3']);
  });

  test('a track of a remote source lands in the music library', () async {
    final file = await service.download(canonicalSong);

    expect(File(file).existsSync(), isTrue);
    expect(await service.storedFileFor(canonicalSong), file);
    expect(
      file,
      path.join(store.path, 'Artist', 'Two', 'Two.mp3'),
    );
    // The copy never leaves the folder the app put it in.
    expect(path.isWithin(store.path, file), isTrue);
  });

  test('two callers share one transfer', () async {
    adapter.gate = Completer<void>();
    final progress = <double>[];

    final first = service.download(song, onProgress: progress.add);
    final second = service.download(song, onProgress: progress.add);
    await adapter.waitForRequest();

    adapter.gate!.complete();
    final file = await first;

    expect(await second, file);
    expect(adapter.requestedUrls, ['https://cdn.test/one.mp3']);
    expect(progress, isNotEmpty);
  });

  test('a newer address replaces the running transfer', () async {
    adapter.gate = Completer<void>();
    final stale = service.download(song);
    // The listener is attached right away, so the cancellation of the stale
    // transfer is never an unhandled error.
    final staleFailure = expectLater(stale, throwsA(isA<StateError>()));
    await adapter.waitForRequest();

    final refreshed = song.copyWith(
      streamUrl: 'https://cdn.test/one.mp3?token=new',
    );
    final fresh = service.download(refreshed);
    adapter.gate!.complete();

    final file = await fresh;
    await staleFailure;

    expect(File(file).existsSync(), isTrue);
    expect(adapter.requestedUrls, [
      'https://cdn.test/one.mp3',
      'https://cdn.test/one.mp3?token=new',
    ]);
  });

  test('a cancelled transfer stops and writes nothing', () async {
    adapter.gate = Completer<void>();
    final transfer = service.download(song);
    // The listener is attached right away, so the cancellation is never an
    // unhandled error.
    final failure = expectLater(transfer, throwsA(isA<StateError>()));
    await adapter.waitForRequest();

    service.cancel(song);
    adapter.gate!.complete();
    await failure;
    await pumpEventQueue();

    final folder = Directory(path.join(store.path, 'Artist', 'One'));
    final files = folder.existsSync()
        ? folder.listSync(recursive: true).whereType<File>()
        : const <File>[];
    expect(files, isEmpty);
  });

  test('a failed transfer leaves nothing behind', () async {
    adapter.failure = StateError('the server said no');

    await expectLater(service.download(song), throwsA(isA<DioException>()));

    final partials = store
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.part'));
    expect(partials, isEmpty);
  });

  test('a partial file of an earlier run does not stop the download', () async {
    final folder = Directory(path.join(store.path, 'Artist', 'One'))
      ..createSync(recursive: true);
    final leftover = File(path.join(folder.path, 'One.mp3.part'));
    await leftover.writeAsString('half a track');

    await service.download(song);

    expect(leftover.existsSync(), isFalse);
    expect(File(path.join(folder.path, 'One.mp3')).existsSync(), isTrue);
  });
}
