import 'dart:math' as math;

import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/discovery/domain/recommendation_candidate.dart';
import 'package:tune/features/discovery/domain/recommendation_reason.dart';
import 'package:tune/features/discovery/domain/recommendation_selection.dart';
import 'package:tune/features/discovery/domain/taste_profile.dart';

DiscoverySection? buildDailyMix({
  required List<RecommendationCandidate> candidates,
  required TasteProfile profile,
  required int seed,
  required Set<String> seen,
}) {
  if (candidates.length < 5) return null;

  final favorites = candidates.where((item) => item.favorite).toList();
  final nonFavorites = candidates.where((item) => !item.favorite).toList();
  final localSeen = <String>{};
  final selected = <RecommendationCandidate>[];

  if (favorites.isNotEmpty) {
    final maxAnchors = nonFavorites.length >= 5
        ? math.min(5, math.max(1, nonFavorites.length ~/ 4))
        : math.min(25, favorites.length);
    final anchors = [...favorites]
      ..sort(RecommendationSelection.compareAnchors);
    for (final anchor in anchors.take(maxAnchors)) {
      selected.add(anchor);
      localSeen.add(anchor.uri);
    }
  }

  final reserved = <String, int>{};
  for (final artist in profile.topArtists(2)) {
    if (nonFavorites.where((item) => item.artistKey == artist).length >= 3) {
      reserved[artist] = 1;
    }
  }

  selected.addAll(
    RecommendationSelection.take(
      nonFavorites,
      limit: 25 - selected.length,
      maxPerArtist: 3,
      maxPerAlbum: 2,
      seen: localSeen,
      artistLimits: reserved,
    ),
  );
  if (selected.length < 5) return null;

  seen.addAll(localSeen);
  final allFavorites = selected.every((item) => item.favorite);
  return DiscoverySection(
    kind: DiscoverySectionKind.dailyMix,
    reason: allFavorites
        ? const RecommendationReason.favorite()
        : const RecommendationReason.fallback(),
    tracks: RecommendationSelection.tracks(selected),
  );
}

List<DiscoverySection> buildArtistSections({
  required List<RecommendationCandidate> candidates,
  required TasteProfile profile,
  required Set<String> seen,
}) {
  final sections = <DiscoverySection>[];
  for (final artistKey in profile.topArtists(2)) {
    final pool = candidates
        .where((item) => !item.favorite && item.artistKey == artistKey)
        .toList(growable: false);
    if (pool.length < 3) continue;

    final localSeen = {...seen};
    final selected = RecommendationSelection.take(
      pool,
      limit: 8,
      maxPerArtist: 8,
      maxPerAlbum: 2,
      seen: localSeen,
    );
    if (selected.length < 3) continue;

    seen.addAll(localSeen);
    final artist = selected.first.song.artist;
    final reason = RecommendationReason(
      kind: RecommendationReasonKind.artist,
      artist: artist,
      confidence: 1,
    );
    sections.add(
      DiscoverySection(
        kind: DiscoverySectionKind.artist,
        reason: reason,
        tracks: RecommendationSelection.tracks(selected, forced: reason),
      ),
    );
  }
  return sections;
}
