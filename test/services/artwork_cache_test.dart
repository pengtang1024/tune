import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/impl/artwork_cache_io.dart';

/// The cover is kept on disk, so a restart does not fetch it again.
void main() {
  late Directory folder;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('tune_artwork');
  });

  tearDown(() async {
    if (await folder.exists()) await folder.delete(recursive: true);
  });

  FileArtworkCache cacheWith(FakeAdapter adapter) => FileArtworkCache(
    client: Dio()..httpClientAdapter = adapter,
    storeDirectory: () async => folder,
  );

  test('a cover is fetched once and then read from the disk', () async {
    final adapter = FakeAdapter();
    final cache = cacheWith(adapter);

    final first = await cache.bytesFor('https://example.com/cover.png');
    final second = await cache.bytesFor('https://example.com/cover.png');

    expect(first, FakeAdapter.bytes);
    expect(second, FakeAdapter.bytes);
    expect(adapter.calls, 1, reason: 'the second time comes from the disk');
  });

  test('the cover is kept in the artwork folder of the app', () async {
    await cacheWith(FakeAdapter()).bytesFor('https://example.com/cover.png');

    final artwork = Directory('${folder.path}/artwork');
    expect(await artwork.exists(), isTrue);
    expect(artwork.listSync().whereType<File>(), hasLength(1));
  });

  test('two caches on one folder keep one copy', () async {
    final first = FakeAdapter();
    final second = FakeAdapter();

    await cacheWith(first).bytesFor('https://example.com/cover.png');
    await cacheWith(second).bytesFor('https://example.com/cover.png');

    expect(first.calls, 1);
    expect(second.calls, 0, reason: 'the second cache finds the stored cover');
  });

  test('two covers of the same address are fetched once', () async {
    final adapter = FakeAdapter();
    final cache = cacheWith(adapter);

    await Future.wait([
      cache.bytesFor('https://example.com/cover.png'),
      cache.bytesFor('https://example.com/cover.png'),
    ]);

    expect(adapter.calls, 1);
  });

  test('a cover that cannot be fetched is not stored', () async {
    final adapter = FakeAdapter(missing: true);
    final cache = cacheWith(adapter);

    await expectLater(
      cache.bytesFor('https://example.com/gone.png'),
      throwsA(isA<DioException>()),
    );

    final artwork = Directory('${folder.path}/artwork');
    final stored = await artwork.exists()
        ? artwork.listSync().whereType<File>()
        : const <File>[];
    expect(stored, isEmpty);
  });
}

/// A client that answers every request with the same bytes.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter({this.missing = false});

  /// Whether the cover is not there.
  final bool missing;

  /// How many requests the adapter answered.
  int calls = 0;

  static final Uint8List bytes = Uint8List.fromList([1, 2, 3, 4]);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (missing) {
      return ResponseBody.fromBytes(const <int>[], 404);
    }
    return ResponseBody.fromBytes(
      bytes,
      200,
      headers: {Headers.contentTypeHeader: ['image/png']},
    );
  }

  @override
  void close({bool force = false}) {}
}
