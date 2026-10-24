import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/discovery/domain/recommendation_candidate.dart';
import 'package:tune/features/discovery/domain/recommendation_reason.dart';
import 'package:tune/features/discovery/domain/recommendation_selection.dart';
import 'package:tune/features/discovery/domain/taste_profile.dart';

DiscoverySection? buildExploreSection({
  required List<RecommendationCandidate> candidates,
  required TasteProfile profile,
  required Set<String> seen,
}) {
  final topGenres = profile.topGenres(2).toSet();
  final topArtists = profile.topArtists(2).toSet();
  final nonFavorites = candidates.where((item) => !item.favorite).toList();
  if (nonFavorites.isEmpty) return null;

  var pool = nonFavorites
      .where(
        (item) =>
            item.artistKey.isNotEmpty &&
            !topArtists.contains(item.artistKey) &&
            (item.genres.isEmpty ||
                item.genres.keys.any((key) => !topGenres.contains(key))),
      )
      .toList();
  if (pool.length < 3) {
    pool = nonFavorites
        .where(
          (item) =>
              item.artistKey.isNotEmpty && !topArtists.contains(item.artistKey),
        )
        .toList();
  }
  if (pool.length < 3) {
    pool = nonFavorites
        .where(
          (item) => item.genres.keys.any((key) => !topGenres.contains(key)),
        )
        .toList();
  }
  if (pool.length < 3) pool = nonFavorites;

  final localSeen = {...seen};
  final selected = RecommendationSelection.take(
    pool,
    limit: 8,
    maxPerArtist: 2,
    maxPerAlbum: 2,
    seen: localSeen,
  );
  if (selected.length < 3) return null;

  seen.addAll(localSeen);
  final reason = _exploreReason(selected, profile, topGenres);
  return DiscoverySection(
    kind: DiscoverySectionKind.explore,
    reason: reason,
    tracks: RecommendationSelection.tracks(selected, forced: reason),
  );
}

RecommendationReason _exploreReason(
  List<RecommendationCandidate> selected,
  TasteProfile profile,
  Set<String> topGenres,
) {
  if (profile.isEmpty) return const RecommendationReason.fallback();
  for (final item in selected) {
    for (final entry in item.genres.entries) {
      if (!topGenres.contains(entry.key)) {
        return RecommendationReason(
          kind: RecommendationReasonKind.genre,
          genre: entry.value,
          confidence: 1,
        );
      }
    }
  }
  for (final item in selected) {
    if (item.decade != null && !profile.decades.containsKey(item.decade)) {
      return RecommendationReason(
        kind: RecommendationReasonKind.era,
        decade: item.decade,
        confidence: 1,
      );
    }
  }
  return const RecommendationReason.fallback();
}
