import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/impl/artwork_cache_io.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/impl/library_paths_io.dart';

import 'fake_persistence.dart';

/// The cover is kept on disk, so a restart does not fetch it again.
void main() {
  late Directory folder;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('tune_artwork');
  });

  tearDown(() async {
    if (await folder.exists()) await folder.delete(recursive: true);
  });

  FileArtworkCache cacheWith(FakeAdapter adapter) {
    final persistence = FakePersistenceService()
      ..values[LibraryPaths.rootKey] = folder.path;
    return FileArtworkCache(
      FileLibraryPaths(persistence),
      client: Dio()..httpClientAdapter = adapter,
    );
  }

  test('a cover is fetched once and then read from the disk', () async {
    final adapter = FakeAdapter();
    final cache = cacheWith(adapter);

    final first = await cache.imageFor('https://example.com/cover.png');
    final second = await cache.imageFor('https://example.com/cover.png');

    expect(first.bytes, FakeAdapter.bytes);
    expect(second.bytes, FakeAdapter.bytes);
    expect(adapter.calls, 1, reason: 'the second time comes from the disk');
  });

  test('the cover is kept in the artwork folder of the music library', () async {
    await cacheWith(FakeAdapter()).imageFor('https://example.com/cover.png');

    final artwork = Directory(path.join(folder.path, '.tune', 'artwork'));
    expect(await artwork.exists(), isTrue);
    expect(_filesIn(artwork), hasLength(1));
  });

  test('the covers are spread over subfolders', () async {
    final adapter = FakeAdapter();
    final cache = cacheWith(adapter);

    for (var index = 0; index < 40; index++) {
      await cache.imageFor('https://example.com/cover$index.png');
    }

    final artwork = Directory(path.join(folder.path, '.tune', 'artwork'));
    final buckets = artwork.listSync().whereType<Directory>();
    expect(buckets.length, greaterThan(1));
    for (final bucket in buckets) {
      expect(bucket.listSync().whereType<File>().length, lessThan(40));
    }
  });

  test('two caches on one folder keep one copy', () async {
    final first = FakeAdapter();
    final second = FakeAdapter();

    await cacheWith(first).imageFor('https://example.com/cover.png');
    await cacheWith(second).imageFor('https://example.com/cover.png');

    expect(first.calls, 1);
    expect(second.calls, 0, reason: 'the second cache finds the stored cover');
  });

  test('two covers of the same address are fetched once', () async {
    final adapter = FakeAdapter();
    final cache = cacheWith(adapter);

    await Future.wait([
      cache.imageFor('https://example.com/cover.png'),
      cache.imageFor('https://example.com/cover.png'),
    ]);

    expect(adapter.calls, 1);
  });

  test('the file of a cover that was fetched is known', () async {
    final cache = cacheWith(FakeAdapter());

    expect(cache.coverFileFor('https://example.com/cover.png'), isNull);

    await cache.imageFor('https://example.com/cover.png');

    final file = cache.coverFileFor('https://example.com/cover.png');
    expect(file, isNotNull);
    expect(File(file!).existsSync(), isTrue);
  });

  test('a cover that cannot be fetched is not stored', () async {
    final adapter = FakeAdapter(missing: true);
    final cache = cacheWith(adapter);

    await expectLater(
      cache.imageFor('https://example.com/gone.png'),
      throwsA(isA<DioException>()),
    );

    final artwork = Directory(path.join(folder.path, '.tune', 'artwork'));
    final stored = await artwork.exists() ? _filesIn(artwork) : <File>[];
    expect(stored, isEmpty);
  });
}

/// The files in a folder and in the folders below it.
List<File> _filesIn(Directory directory) {
  return directory.listSync(recursive: true).whereType<File>().toList();
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
