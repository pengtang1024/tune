import 'package:tune/features/discovery/domain/recommendation_candidate.dart';
import 'package:tune/features/discovery/domain/recommendation_selection.dart';

/// Puts the daily mix in an order that is pleasant to listen to.
///
/// The set is already chosen; this only arranges it. The best remaining track
/// goes first, then the best one that does not repeat the previous artist or
/// album. When no such track is left, the artist rule is relaxed before the
/// album rule, and only then is a direct repeat allowed.
class RecommendationSequencer {
  const RecommendationSequencer._();

  static List<RecommendationCandidate> order(
    List<RecommendationCandidate> selected,
  ) {
    if (selected.length < 2) return selected;

    final remaining = [...selected]
      ..sort(RecommendationSelection.compareByScore);
    final ordered = <RecommendationCandidate>[remaining.removeAt(0)];

    while (remaining.isNotEmpty) {
      final previous = ordered.last;
      var index = remaining.indexWhere(
        (item) =>
            item.artistKey != previous.artistKey &&
            item.albumKey != previous.albumKey,
      );
      if (index < 0) {
        index = remaining.indexWhere(
          (item) => item.artistKey != previous.artistKey,
        );
      }
      if (index < 0) index = 0;
      ordered.add(remaining.removeAt(index));
    }
    return ordered;
  }
}
