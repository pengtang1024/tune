import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/sources/application/source_health_reports.dart';

/// The health score of every configured source, between 0 and 1.
///
/// The reports are built by [sourceHealthReportsProvider]; this provider only
/// scales the scores for the recommender. The source page and the discovery
/// page therefore read the same health model instead of computing two.
final sourceHealthScoresProvider = Provider<Map<String, double>>((ref) {
  final reports = ref.watch(sourceHealthReportsProvider);
  return Map.unmodifiable({
    for (final entry in reports.entries) entry.key: entry.value.score / 100,
  });
});

/// The health score of one source, for a caller that already has the map.
double sourceHealthOf(String? sourceId, Map<String, double> scores) {
  if (sourceId == null || sourceId.isEmpty || sourceId == 'local') return 1;
  // Unknown is not neutral: a source missing from the health reports is
  // treated as a negative signal, not as an average source.
  return scores[sourceId] ?? 0.25;
}

/// The health score that belongs to a track.
double trackSourceHealth(Song song, Map<String, double> scores) {
  return sourceHealthOf(song.sourceId, scores);
}
