// Benchmark: the cost of one discovery page computation against a synthetic
// library. Run with: flutter test tool/perf/recommendation_bench_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/recommendation_candidate.dart';
import 'package:tune/features/discovery/domain/recommendation_scoring.dart';
import 'package:tune/features/discovery/domain/recommendation_selection.dart';
import 'package:tune/features/discovery/domain/recommendation_engine.dart';
import 'package:tune/features/discovery/domain/taste_profile.dart';

List<Song> buildLibrary(int count) {
  const genres = ['Rock', 'Jazz', 'Electronic', 'Folk', 'Ambient'];
  return [
    for (var i = 0; i < count; i++)
      Song(
        id: i,
        title: 'Track $i',
        artist: 'Artist ${i % 500}',
        album: 'Album ${i % 900}',
        duration: 200000,
        uri: 'tune://source/track/$i',
        dateAdded: 1750000000000 + i * 1000,
        year: 1980 + (i % 45),
        genres: [genres[i % genres.length]],
        sourceId: 'source-${i % 12}',
      ),
  ];
}

void main() {
  test('discovery page cost against library size', () {
    const engine = RecommendationEngine();
    for (final size in [1000, 5000, 20000, 50000]) {
      final library = buildLibrary(size);
      final favorites = {
        for (var i = 0; i < 200; i++) library[i * 7 % size].uri,
      };

      final sw = Stopwatch()..start();
      final profile = TasteProfile.from(
        library: library,
        favoriteUris: favorites,
      );
      final output = engine.recommend(
        library: library,
        favoriteUris: favorites,
        profile: profile,
        dismissedUris: const {},
        sourceOrder: List.generate(12, (i) => 'source-$i'),
        dateKey: '2026-10-24',
        refreshSalt: 0,
        allowFresh: true,
        now: DateTime(2026, 10, 24),
      );
      sw.stop();

      final tracks = output.sections.fold<int>(
        0,
        (sum, section) => sum + section.tracks.length,
      );
      // ignore: avoid_print
      print(
        'library=$size  sections=${output.sections.length}  tracks=$tracks  '
        'compute=${sw.elapsedMilliseconds}ms',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('breakdown', () {
    breakdown();
  }, timeout: const Timeout(Duration(minutes: 5)));
}

// Breakdown of the discovery computation: how much is candidate building,
// how much is scoring, and how much is the section building.
void breakdown() {
  const engine = RecommendationEngine();
  for (final size in [20000, 50000]) {
    final library = buildLibrary(size);
    final favorites = {for (var i = 0; i < 200; i++) library[i * 7 % size].uri};
    final profile = TasteProfile.from(library: library, favoriteUris: favorites);

    var sw = Stopwatch()..start();
    final candidates = buildCandidates(
      library: library,
      favoriteUris: favorites,
      dismissedUris: const {},
    );
    sw.stop();
    final buildMs = sw.elapsedMilliseconds;

    sw = Stopwatch()..start();
    scoreCandidates(candidates, profile: profile, allowFresh: true, now: DateTime(2026, 10, 24));
    sw.stop();
    final scoreMs = sw.elapsedMilliseconds;

    sw = Stopwatch()..start();
    RecommendationSelection.sortByScore(candidates, 12345);
    sw.stop();
    final sortMs = sw.elapsedMilliseconds;

    sw = Stopwatch()..start();
    engine.recommend(
      library: library,
      favoriteUris: favorites,
      profile: profile,
      dismissedUris: const {},
      sourceOrder: List.generate(12, (i) => 'source-$i'),
      dateKey: '2026-10-24',
      refreshSalt: 0,
      allowFresh: true,
      now: DateTime(2026, 10, 24),
    );
    sw.stop();
    final totalMs = sw.elapsedMilliseconds;

    // ignore: avoid_print
    print(
      'library=$size total=${totalMs}ms  candidates=${buildMs}ms  '
      'scoring=${scoreMs}ms  sort=${sortMs}ms  '
      'sections=${totalMs - buildMs - scoreMs - sortMs}ms',
    );
  }
}
