// Benchmark: how long the database work of the library costs on a large
// collection, split by the statements the page actually runs. Run with:
// flutter test tool/perf/db_bench_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/data/services/database/facets_worker.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/domain/library_filter.dart';
import 'package:tune/features/library/domain/library_sort.dart';

const _sizes = [20000, 50000];

String _seededPath(int size) {
  final path = '${Directory.systemTemp.path}/tune_db_bench_$size.db';
  final file = File(path);
  if (file.existsSync()) file.deleteSync();
  final db = AppDatabase.open(path);
  final now = DateTime.now().millisecondsSinceEpoch;
  db.ingestBatch([
    for (var i = 0; i < size; i++)
      Song(
        id: i + 1,
        title: 'Track $i',
        artist: 'Artist ${i % 500}',
        album: 'Album ${i % 2000}',
        year: 1960 + (i % 60),
        genre: ['Jazz', 'Rock', 'Pop', 'Electronic'][i % 4],
        genres: [['Jazz', 'Rock', 'Pop', 'Electronic'][i % 4]],
        duration: 120000 + (i % 8) * 60000,
        language: ['zh', 'en', 'ja'][i % 3],
        type: ['audio/mpeg', 'audio/flac', 'audio/ogg'][i % 3],
        uri: '/music/$i.mp3',
        dateAdded: now - (i % 1000) * 86400000,
      ),
  ]);
  db.close();
  return path;
}

int _median(void Function() body, {int runs = 7}) {
  final samples = <int>[];
  for (var i = 0; i < runs; i++) {
    final watch = Stopwatch()..start();
    body();
    samples.add(watch.elapsedMicroseconds);
  }
  samples.sort();
  return samples[samples.length ~/ 2] ~/ 1000;
}

Future<int> _medianAsync(Future<void> Function() body, {int runs = 3}) async {
  final samples = <int>[];
  for (var i = 0; i < runs; i++) {
    final watch = Stopwatch()..start();
    await body();
    samples.add(watch.elapsedMicroseconds);
  }
  samples.sort();
  return samples[samples.length ~/ 2] ~/ 1000;
}

void main() {
  for (final size in _sizes) {
    test('$size tracks: the read path the library page runs', () async {
      final path = _seededPath(size);
      final db = AppDatabase.open(path);
      const empty = LibraryFilter();
      const someFilters = LibraryFilter(
        genres: {'jazz', 'rock'},
        decades: {1990, 2000},
        durations: {LibraryDurationBucket.medium},
      );

      final recent0 = _median(
        () => db.query(
          query: '',
          filter: empty,
          sort: LibrarySort.recent,
          offset: 0,
          limit: 1000,
        ),
      );
      final recentDeep = _median(
        () => db.query(
          query: '',
          filter: empty,
          sort: LibrarySort.recent,
          offset: size ~/ 2,
          limit: 1000,
        ),
      );
      final byTitle = _median(
        () => db.query(
          query: '',
          filter: empty,
          sort: LibrarySort.title,
          offset: 0,
          limit: 1000,
        ),
      );
      final byArtist = _median(
        () => db.query(
          query: '',
          filter: empty,
          sort: const LibrarySort(field: LibrarySortField.artist),
          offset: 0,
          limit: 1000,
        ),
      );
      final search = _median(
        () => db.query(
          query: 'Track 1',
          filter: empty,
          sort: LibrarySort.recent,
          offset: 0,
          limit: 1000,
        ),
      );
      final count = _median(() => db.countQuery(query: '', filter: empty));
      final filtered = _median(
        () => db.query(
          query: '',
          filter: someFilters,
          sort: LibrarySort.recent,
          offset: 0,
          limit: 1000,
        ),
      );
      final facets = _median(() => db.facets(filter: empty), runs: 3);
      // What the page actually waits for: the counts run on a worker isolate
      // with its own read connection, so the UI thread only spawns it and
      // waits for the maps.
      final facetsOffThread = await _medianAsync(() async {
        final result = await facetsInBackground(
          path: path,
          filter: someFilters,
        );
        if (result.artists.isEmpty) throw StateError('empty facets');
      });
      final albums = _median(() => db.albumSummaries(), runs: 3);
      final albumCount = db.albumSummaries().length;
      // What one pause of typing used to pay, and what it pays now: the
      // album shelf no longer comes along with a search.
      final reloadBefore = _median(() {
        db.countQuery(query: 'Track 1', filter: empty);
        db.query(
          query: 'Track 1',
          filter: empty,
          sort: LibrarySort.recent,
          offset: 0,
          limit: 1000,
        );
        db.albumSummaries();
      });
      final reloadAfter = _median(() {
        db.countQuery(query: 'Track 1', filter: empty);
        db.query(
          query: 'Track 1',
          filter: empty,
          sort: LibrarySort.recent,
          offset: 0,
          limit: 1000,
        );
      });
      // ignore: avoid_print
      print(
        'db $size: recent0=${recent0}ms recentDeep=${recentDeep}ms '
        'title=${byTitle}ms artist=${byArtist}ms search=${search}ms '
        'count=${count}ms filtered=${filtered}ms '
        'facets=${facets}ms facetsOffThread=${facetsOffThread}ms '
        'albums=${albums}ms '
        '($albumCount albums) pause=${reloadBefore}ms'
        '->${reloadAfter}ms',
      );
      db.close();
      File(path).deleteSync();
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}
