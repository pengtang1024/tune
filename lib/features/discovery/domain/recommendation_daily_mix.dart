import 'dart:math' as math;

import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/discovery/domain/recommendation_candidate.dart';
import 'package:tune/features/discovery/domain/recommendation_reason.dart';
import 'package:tune/features/discovery/domain/recommendation_selection.dart';
import 'package:tune/features/discovery/domain/recommendation_sequencer.dart';
import 'package:tune/features/discovery/domain/recommendation_tuning.dart';
import 'package:tune/features/discovery/domain/taste_profile.dart';

DiscoverySection? buildDailyMix({
  required List<RecommendationCandidate> candidates,
  required TasteProfile profile,
  required RecommendationTuning tuning,
  required int seed,
  required Set<String> seen,
}) {
  if (candidates.length < 5) return null;

  final favorites = candidates.where((item) => item.favorite).toList();
  final nonFavorites = candidates.where((item) => !item.favorite).toList();
  final localSeen = <String>{};
  final selected = <RecommendationCandidate>[];

  final weakProfile = profile.confidence < tuning.weakProfileThreshold;
  if (favorites.isNotEmpty) {
    final anchorsWanted = weakProfile ? 1 : tuning.favoriteAnchors;
    final maxAnchors = nonFavorites.isEmpty
        ? math.min(tuning.dailyMixSize, favorites.length)
        : math.min(anchorsWanted, favorites.length);
    final anchors = [...favorites]
      ..sort((left, right) => _compareFavorites(left, right, seed));
    for (final anchor in anchors.take(maxAnchors)) {
      selected.add(anchor);
      localSeen.add(anchor.uri);
    }
  }

  final topArtists = profile.topArtists(2).toSet();
  final topGenres = profile.topGenres(2).toSet();
  final topDecades = profile.topDecades(2).toSet();

  final exploration = nonFavorites
      .where(
        (item) =>
            !localSeen.contains(item.uri) &&
            item.novelty >= 0.8 &&
            !topArtists.contains(item.artistKey),
      )
      .toList(growable: false);
  selected.addAll(
    RecommendationSelection.take(
      exploration,
      limit:
          tuning.explorationSlots +
          (weakProfile ? tuning.weakExplorationBonus : 0),
      maxPerArtist: 2,
      maxPerAlbum: 2,
      seen: localSeen,
    ),
  );

  final adjacent = nonFavorites
      .where(
        (item) =>
            !localSeen.contains(item.uri) &&
            !topArtists.contains(item.artistKey) &&
            (item.genres.keys.any(topGenres.contains) ||
                (item.decade != null && topDecades.contains(item.decade))),
      )
      .toList(growable: false);
  selected.addAll(
    RecommendationSelection.take(
      adjacent,
      limit:
          tuning.adjacentSlots + (weakProfile ? tuning.weakAdjacentBonus : 0),
      maxPerArtist: 2,
      maxPerAlbum: 2,
      seen: localSeen,
    ),
  );

  final reserved = <String, int>{};
  for (final artist in topArtists) {
    if (nonFavorites.where((item) => item.artistKey == artist).length >= 3) {
      reserved[artist] = 1;
    }
  }
  final artistCounts = <String, int>{};
  final albumCounts = <String, int>{};
  for (final item in selected) {
    if (item.artistKey.isNotEmpty) {
      artistCounts[item.artistKey] = (artistCounts[item.artistKey] ?? 0) + 1;
    }
    if (item.albumKey.isNotEmpty) {
      albumCounts[item.albumKey] = (albumCounts[item.albumKey] ?? 0) + 1;
    }
  }
  selected.addAll(
    RecommendationSelection.take(
      nonFavorites,
      limit: tuning.dailyMixSize - selected.length,
      maxPerArtist: 3,
      maxPerAlbum: 2,
      seen: localSeen,
      artistLimits: reserved,
      initialArtists: artistCounts,
      initialAlbums: albumCounts,
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
    tracks: RecommendationSelection.tracks(
      RecommendationSequencer.order(selected),
    ),
  );
}

List<DiscoverySection> buildArtistSections({
  required List<RecommendationCandidate> candidates,
  required TasteProfile profile,
  required RecommendationTuning tuning,
  required Set<String> seen,
}) {
  final sections = <DiscoverySection>[];
  for (final artistKey in profile.topArtists(2)) {
    final pool = candidates
        .where((item) => !item.favorite && item.artistKey == artistKey)
        .toList(growable: false);
    if (pool.length < tuning.artistShelfMinTracks) continue;

    final localSeen = {...seen};
    final selected = RecommendationSelection.take(
      pool,
      limit: 8,
      maxPerArtist: 8,
      maxPerAlbum: 2,
      seen: localSeen,
    );
    if (selected.length < tuning.artistShelfMinTracks) continue;

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

int _compareFavorites(
  RecommendationCandidate left,
  RecommendationCandidate right,
  int seed,
) {
  final leftAt = left.listening.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
  final rightAt = right.listening.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
  if (leftAt != rightAt) return leftAt.compareTo(rightAt);
  return RecommendationSelection.compareAnchors(left, right);
}
