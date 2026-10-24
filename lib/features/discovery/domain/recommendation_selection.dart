import 'package:tune/features/discovery/domain/recommendation_candidate.dart';
import 'package:tune/features/discovery/domain/recommendation_reason.dart';
import 'package:tune/features/discovery/domain/recommendation_scoring.dart';
import 'package:tune/features/discovery/domain/recommended_track.dart';

/// Picks tracks out of a pool without repeating one and without letting one
/// artist or album fill the whole row.
class RecommendationSelection {
  const RecommendationSelection._();

  static List<RecommendationCandidate> sortByScore(
    Iterable<RecommendationCandidate> pool,
    int seed,
  ) {
    return [...pool]..sort((left, right) => compareByScore(left, right, seed));
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
    int seed,
  ) {
    final byScore = right.score.compareTo(left.score);
    if (byScore != 0) return byScore;
    return compareAnchors(left, right, seed);
  }

  static int compareAnchors(
    RecommendationCandidate left,
    RecommendationCandidate right,
    int seed,
  ) {
    final byHash = stableHashOf(
      '${left.uri}|$seed',
    ).compareTo(stableHashOf('${right.uri}|$seed'));
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
