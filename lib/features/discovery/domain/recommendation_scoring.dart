import 'dart:math' as math;

import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/recommendation_candidate.dart';
import 'package:tune/features/discovery/domain/recommendation_reason.dart';
import 'package:tune/features/discovery/domain/recommendation_tuning.dart';
import 'package:tune/features/discovery/domain/taste_profile.dart';

/// Scores every candidate and gives it the reason that fits it best.
void scoreCandidates(
  List<RecommendationCandidate> candidates, {
  required TasteProfile profile,
  required bool allowFresh,
  required DateTime now,
  Map<String, double> sourceHealth = const {},
  RecommendationTuning tuning = RecommendationTuning.defaults,
}) {
  for (final candidate in candidates) {
    final artist = profile.artistWeightKey(candidate.artistKey);
    final genre = _strongestGenreWeight(candidate, profile);
    final era = profile.decadeWeight(candidate.decade);
    final album = profile.albumWeightKey(candidate.albumKey);
    final quality = _qualityOf(candidate);
    final novelty = _noveltyOf(candidate, now);
    final freshness = allowFresh ? freshnessOf(candidate.song, now) : 0.0;
    final recent = _recentPenalty(candidate, now, tuning.recentDays);
    final skip = _skipPenalty(candidate, now, tuning.skipHalfLifeDays);
    final health = _sourceHealthOf(candidate.song.sourceId, sourceHealth);
    final healthFactor = 1 - tuning.sourceHealthWeight * (1 - health);
    final missingArtwork = candidate.song.hasArtwork ? 0.0 : 1.0;

    final base =
        tuning.artistWeight * artist +
        tuning.genreWeight * genre +
        tuning.eraWeight * era +
        tuning.albumWeight * album +
        tuning.qualityWeight * quality +
        tuning.noveltyWeight * novelty +
        tuning.freshnessWeight * freshness;
    final favorite = candidate.favorite ? tuning.favoriteBoost : 0.0;

    candidate.quality = quality;
    candidate.novelty = novelty;
    candidate.recentPenalty = recent;
    candidate.skipPenalty = skip;
    candidate.sourceHealth = health;
    final baseScore =
        (base +
                favorite -
                tuning.recentPenalty * recent -
                tuning.skipPenalty * skip -
                tuning.artworkPenalty * missingArtwork)
            .clamp(0.0, 1.0)
            .toDouble();
    candidate.score = (baseScore * healthFactor).clamp(0.0, 1.0).toDouble();
    candidate.reason = _reasonFor(candidate, profile, now);
  }
}

/// How much of a track feels fresh, between 0 and 1.
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

double _qualityOf(RecommendationCandidate candidate) {
  final signal = candidate.listening;
  if (signal.listens == 0 && signal.skips == 0) {
    return candidate.favorite ? 0.7 : 0.5;
  }
  if (signal.listens == 0) return 0;
  final completion = signal.completions / signal.listens;
  final skipRate = signal.skips / (signal.listens + signal.skips);
  return (0.4 + 0.6 * completion - 0.4 * skipRate).clamp(0.0, 1.0).toDouble();
}

double _noveltyOf(RecommendationCandidate candidate, DateTime now) {
  final signal = candidate.listening;
  if (signal.listens == 0 && signal.skips == 0) return 1;
  final age = _daysSince(signal.lastPlayedAt, now);
  if (age == null) return 0.7;
  if (age > 60) return 0.8;
  if (age > 30) return 0.6;
  return 0.3;
}

double _recentPenalty(
  RecommendationCandidate candidate,
  DateTime now,
  int recentDays,
) {
  final age = _daysSince(candidate.listening.lastPlayedAt, now);
  if (age == null) return 0;
  if (age <= 7) return 1;
  if (age >= recentDays) return 0;
  return (recentDays - age) / (recentDays - 7);
}

double _skipPenalty(
  RecommendationCandidate candidate,
  DateTime now,
  int halfLifeDays,
) {
  final signal = candidate.listening;
  final total = signal.listens + signal.skips;
  if (total == 0) return 0;
  final rate = (signal.skips / total).clamp(0.0, 1.0).toDouble();
  final age = _daysSince(signal.lastPlayedAt, now);
  if (age == null) return rate;
  final decay = math.pow(0.5, age / halfLifeDays).toDouble();
  return (rate * decay).clamp(0.0, 1.0).toDouble();
}

double? _daysSince(DateTime? at, DateTime now) {
  if (at == null) return null;
  return now.difference(at).inHours / 24;
}

RecommendationReason _reasonFor(
  RecommendationCandidate candidate,
  TasteProfile profile,
  DateTime now,
) {
  if (candidate.favorite) return const RecommendationReason.favorite();
  if (profile.isEmpty) {
    return candidate.listening.listens > 0
        ? const RecommendationReason.fallback()
        : const RecommendationReason(
            kind: RecommendationReasonKind.unheard,
            confidence: 1,
          );
  }

  final artist = profile.artistWeightKey(candidate.artistKey);
  final genre = _strongestGenreWeight(candidate, profile);
  final era = profile.decadeWeight(candidate.decade);

  if (artist >= 0.20 && candidate.artistKey.isNotEmpty) {
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
  if (era >= 0.08 && candidate.decade != null) {
    return RecommendationReason(
      kind: RecommendationReasonKind.era,
      decade: candidate.decade,
      confidence: era,
    );
  }
  if (freshnessOf(candidate.song, now) >= 0.2) {
    return const RecommendationReason.fresh();
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

double _sourceHealthOf(String? sourceId, Map<String, double> scores) {
  if (sourceId == null || sourceId.isEmpty || sourceId == 'local') return 1;
  return (scores[sourceId] ?? 0.25).clamp(0.0, 1.0).toDouble();
}
