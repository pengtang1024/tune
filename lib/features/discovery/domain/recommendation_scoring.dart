import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/recommendation_candidate.dart';
import 'package:tune/features/discovery/domain/recommendation_reason.dart';
import 'package:tune/features/discovery/domain/taste_profile.dart';

/// Scores every candidate and gives it the reason that fits it best.
void scoreCandidates(
  List<RecommendationCandidate> candidates, {
  required TasteProfile profile,
  required bool allowFresh,
  required DateTime now,
}) {
  for (final candidate in candidates) {
    final parts = <_ScorePart>[];

    if (profile.artists.isNotEmpty) {
      parts.add(_ScorePart(0.40, profile.artistWeightKey(candidate.artistKey)));
    }
    if (profile.genres.isNotEmpty) {
      final strongest = _strongestGenreWeight(candidate, profile);
      parts.add(_ScorePart(0.25, strongest));
    }
    if (profile.decades.isNotEmpty) {
      parts.add(_ScorePart(0.15, profile.decadeWeight(candidate.decade)));
    }
    parts.add(_ScorePart(0.10, candidate.favorite ? 0.2 : 1.0));
    if (allowFresh) {
      parts.add(_ScorePart(0.10, freshnessOf(candidate.song, now)));
    }

    final total = parts.fold<double>(0, (sum, part) => sum + part.weight);
    candidate.score = total <= 0
        ? 0
        : parts.fold<double>(0, (sum, part) => sum + part.weight * part.value) /
              total;
    candidate.reason = _reasonFor(
      candidate,
      profile,
      total,
      allowFresh: allowFresh,
      now: now,
    );
  }
}

/// The fraction of a track's listen that makes it feel fresh, between 0 and 1.
double freshnessOf(Song song, DateTime now) {
  if (song.dateAdded <= 0) return 0;
  final added = DateTime.fromMillisecondsSinceEpoch(song.dateAdded);
  final age = now.difference(added).inHours / 24;
  if (age <= 0) return 1;
  return (1 - age / 30).clamp(0.0, 1.0).toDouble();
}

/// A stable, platform-independent hash used for the daily seed and ties.
int stableHashOf(String value) {
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash;
}

RecommendationReason _reasonFor(
  RecommendationCandidate candidate,
  TasteProfile profile,
  double total, {
  required bool allowFresh,
  required DateTime now,
}) {
  if (candidate.favorite) return const RecommendationReason.favorite();
  if (total <= 0) return const RecommendationReason.fallback();

  final artist = profile.artists.isEmpty
      ? 0.0
      : 0.40 * profile.artistWeightKey(candidate.artistKey) / total;
  final genre = profile.genres.isEmpty
      ? 0.0
      : 0.25 * _strongestGenreWeight(candidate, profile) / total;
  final era = profile.decades.isEmpty
      ? 0.0
      : 0.15 * profile.decadeWeight(candidate.decade) / total;
  final fresh = allowFresh
      ? 0.10 * freshnessOf(candidate.song, now) / total
      : 0.0;

  if (artist >= 0.18 && candidate.artistKey.isNotEmpty) {
    return RecommendationReason(
      kind: RecommendationReasonKind.artist,
      artist: candidate.song.artist,
      confidence: artist,
    );
  }
  if (genre >= 0.14 && candidate.genres.isNotEmpty) {
    final strongest = _strongestGenreKey(candidate, profile);
    return RecommendationReason(
      kind: RecommendationReasonKind.genre,
      genre: candidate.genres[strongest],
      confidence: genre,
    );
  }
  if (era >= 0.10 && candidate.decade != null) {
    return RecommendationReason(
      kind: RecommendationReasonKind.era,
      decade: candidate.decade,
      confidence: era,
    );
  }
  if (fresh >= 0.12) return const RecommendationReason.fresh();
  if (profile.isEmpty) {
    return fresh > 0
        ? const RecommendationReason.fresh()
        : const RecommendationReason(
            kind: RecommendationReasonKind.unheard,
            confidence: 1,
          );
  }
  return const RecommendationReason.fallback();
}

double _strongestGenreWeight(
  RecommendationCandidate candidate,
  TasteProfile profile,
) {
  if (candidate.genres.isEmpty) return 0;
  var best = 0.0;
  for (final key in candidate.genres.keys) {
    final weight = profile.genreWeightKey(key);
    if (weight > best) best = weight;
  }
  return best;
}

String _strongestGenreKey(
  RecommendationCandidate candidate,
  TasteProfile profile,
) {
  var best = candidate.genres.keys.first;
  var bestWeight = -1.0;
  for (final key in candidate.genres.keys) {
    final weight = profile.genreWeightKey(key);
    if (weight > bestWeight) {
      best = key;
      bestWeight = weight;
    }
  }
  return best;
}

class _ScorePart {
  final double weight;
  final double value;

  const _ScorePart(this.weight, this.value);
}
