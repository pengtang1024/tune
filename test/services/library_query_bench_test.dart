import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/domain/library_filter.dart';
import 'package:tune/features/library/domain/library_sort.dart';

/// The filter and facet budget of docs/library-browse.md §6, measured on a
/// library of twenty thousand tracks.
void main() {
  test('a 20k library filters and counts inside the budget', () {
    final db = AppDatabase.inMemory();
    final now = DateTime.now().millisecondsSinceEpoch;
    db.ingestBatch([
      for (var i = 0; i < 20000; i++)
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

    final filter = const LibraryFilter(
      genres: {'jazz', 'rock'},
      decades: {1990, 2000},
      formats: {'mp3'},
      languages: {'zh', 'en'},
      durations: {LibraryDurationBucket.medium},
    );

    final queryWatch = Stopwatch()..start();
    final page = db.query(
      query: '',
      filter: filter,
      sort: LibrarySort.recent,
      offset: 0,
      limit: 100,
    );
    queryWatch.stop();

    final countWatch = Stopwatch()..start();
    final count = db.countQuery(query: '', filter: filter);
    countWatch.stop();

    final facetWatch = Stopwatch()..start();
    final facets = db.facets(filter: filter);
    facetWatch.stop();

    // ignore: avoid_print
    print(
      '20k query=${queryWatch.elapsedMilliseconds}ms '
      'count=${countWatch.elapsedMilliseconds}ms '
      'facets=${facetWatch.elapsedMilliseconds}ms',
    );
    expect(page, isNotEmpty);
    expect(count, greaterThan(0));
    expect(facets.genres, isNotEmpty);
    expect(queryWatch.elapsedMilliseconds, lessThan(1000));
    expect(countWatch.elapsedMilliseconds, lessThan(1000));
    expect(facetWatch.elapsedMilliseconds, lessThan(3000));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
