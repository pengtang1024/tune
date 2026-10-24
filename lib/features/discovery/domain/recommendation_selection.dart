import 'package:tune/features/discovery/domain/recommendation_candidate.dart';
import 'package:tune/features/discovery/domain/recommendation_reason.dart';
import 'package:tune/features/discovery/domain/recommendation_scoring.dart';
import 'package:tune/features/discovery/domain/recommended_track.dart';

/// Picks tracks out of a pool without repeating one and without letting one
/// artist or album fill the whole row.
class RecommendationSelection {
  const RecommendationSelection._();

  /// Sorts a pool by score.
  ///
  /// The engine precomputes [RecommendationCandidate.tieBreak] once. A caller
  /// that only has a raw pool may pass a seed and let this method fill it in.
  static List<RecommendationCandidate> sortByScore(
    Iterable<RecommendationCandidate> pool, [
    int? seed,
  ]) {
    final result = [...pool];
    if (seed != null) {
      for (final item in result) {
        item.tieBreak = stableHashOf('${item.uri}|$seed');
      }
    }
    return result..sort(compareByScore);
  }

  static List<RecommendationCandidate> take(
    List<RecommendationCandidate> sorted, {
    required int limit,
    required int maxPerArtist,
    required int maxPerAlbum,
    required Set<String> seen,
    Map<String, int> artistLimits = const {},
  }) {
    final result = <RecommendationCandidate>[];
    final artists = <String, int>{};
    final albums = <String, int>{};
    for (final item in sorted) {
      if (result.length >= limit) break;
      if (seen.contains(item.uri)) continue;

      final artist = item.artistKey;
      if (artist.isNotEmpty) {
        final cap = artistLimits[artist] ?? maxPerArtist;
        if ((artists[artist] ?? 0) >= cap) continue;
      }
      final album = item.albumKey;
      if (album.isNotEmpty && (albums[album] ?? 0) >= maxPerAlbum) continue;

      result.add(item);
      seen.add(item.uri);
      if (artist.isNotEmpty) artists[artist] = (artists[artist] ?? 0) + 1;
      if (album.isNotEmpty) albums[album] = (albums[album] ?? 0) + 1;
    }
    return result;
  }

  static int compareByScore(
    RecommendationCandidate left,
    RecommendationCandidate right,
  ) {
    final byScore = right.score.compareTo(left.score);
    if (byScore != 0) return byScore;
    return compareAnchors(left, right);
  }

  static int compareAnchors(
    RecommendationCandidate left,
    RecommendationCandidate right,
  ) {
    final byHash = left.tieBreak.compareTo(right.tieBreak);
    if (byHash != 0) return byHash;
    return left.song.title.compareTo(right.song.title);
  }

  static List<RecommendedTrack> tracks(
    List<RecommendationCandidate> selected, {
    RecommendationReason? forced,
  }) {
    return [
      for (final item in selected)
        RecommendedTrack(
          song: item.song,
          score: item.score,
          reason: forced ?? item.reason,
          fromFavorites: item.favorite,
        ),
    ];
  }
}
