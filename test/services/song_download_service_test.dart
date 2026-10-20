import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/impl/http_song_download_service_io.dart';
import 'package:tune/domain/models/song.dart';

void main() {
  late Directory store;
  late FakeHttpAdapter adapter;
  late HttpSongDownloadService service;

  const song = Song(
    id: 1,
    title: 'One',
    artist: 'Artist',
    uri: 'tune://test/one',
    streamUrl: 'https://cdn.test/one.mp3',
  );

  setUp(() async {
    store = await Directory.systemTemp.createTemp('tune-download-test');
    adapter = FakeHttpAdapter();
    service = HttpSongDownloadService(
      client: Dio()..httpClientAdapter = adapter,
      storeDirectory: () async => store,
    );
  });

  tearDown(() async {
    service.dispose();
    if (store.existsSync()) {
      await store.delete(recursive: true);
    }
  });

  test('the fetched track lands in the store', () async {
    final file = await service.download(song);

    expect(File(file).existsSync(), isTrue);
    expect(await service.storedFileFor(song), file);
    expect(adapter.requestedUrls, ['https://cdn.test/one.mp3']);
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

    final downloads = Directory(path.join(store.path, 'downloads'));
    expect(downloads.listSync(), isEmpty);
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

  test('the partial files of an earlier run are removed', () async {
    final downloads = Directory(path.join(store.path, 'downloads'))
      ..createSync(recursive: true);
    final leftover = File(path.join(downloads.path, 'leftover.part'));
    await leftover.writeAsString('half a track');

    await service.download(song);

    expect(leftover.existsSync(), isFalse);
  });
}

/// Answers every request with the same bytes and remembers what was asked.
class FakeHttpAdapter implements HttpClientAdapter {
  /// Holds the answer until the test releases it.
  Completer<void>? gate;

  /// When set the request fails with this error.
  Object? failure;

  /// The addresses that were requested.
  final List<String> requestedUrls = [];

  final List<void Function()> _arrivals = [];

  /// Completes as soon as a request reaches the adapter.
  Future<void> waitForRequest() {
    if (requestedUrls.isNotEmpty) return Future<void>.value();
    final completer = Completer<void>();
    _arrivals.add(completer.complete);
    return completer.future;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedUrls.add(options.uri.toString());
    for (final arrival in List.of(_arrivals)) {
      arrival();
    }
    _arrivals.clear();

    final gate = this.gate;
    if (gate != null) {
      await gate.future;
    }
    final failure = this.failure;
    if (failure != null) {
      throw failure;
    }
    final bytes = Uint8List.fromList(List<int>.filled(1024, 7));
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
