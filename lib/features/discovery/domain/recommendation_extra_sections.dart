import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/discovery/domain/recommendation_candidate.dart';
import 'package:tune/features/discovery/domain/recommendation_reason.dart';
import 'package:tune/features/discovery/domain/recommendation_scoring.dart';
import 'package:tune/features/discovery/domain/recommendation_tuning.dart';
import 'package:tune/features/discovery/domain/recommendation_selection.dart';

DiscoverySection? buildFreshSection({
  required List<RecommendationCandidate> candidates,
  required bool allowFresh,
  required DateTime now,
  required Set<String> seen,
}) {
  if (!allowFresh) return null;
  final cutoff = now.subtract(const Duration(days: 30));
  // The shelf is still made of new tracks, but among them the score decides
  // who gets the eight slots. A month of scans can add a whole source without
  // covers; date alone would fill the shelf with grey cards.
  final pool = RecommendationSelection.sortByScore(
    candidates.where((item) {
      if (item.song.dateAdded <= 0) return false;
      final added = DateTime.fromMillisecondsSinceEpoch(item.song.dateAdded);
      return added.isAfter(cutoff);
    }),
  );
  if (pool.isEmpty) return null;

  final localSeen = {...seen};
  final selected = RecommendationSelection.take(
    pool,
    limit: 8,
    maxPerArtist: 3,
    maxPerAlbum: 2,
    seen: localSeen,
  );
  if (selected.isEmpty) return null;

  seen.addAll(localSeen);
  return DiscoverySection(
    kind: DiscoverySectionKind.fresh,
    reason: const RecommendationReason.fresh(),
    tracks: RecommendationSelection.tracks(
      selected,
      forced: const RecommendationReason.fresh(),
    ),
  );
}

List<DiscoverySection> buildSourceSections({
  required List<RecommendationCandidate> candidates,
  required List<String> sourceOrder,
  Map<String, double> sourceHealth = const {},
  RecommendationTuning tuning = RecommendationTuning.defaults,
  required Set<String> seen,
}) {
  final groups = <String, List<RecommendationCandidate>>{};
  for (final item in candidates) {
    if (item.favorite) continue;
    final sourceId = item.song.sourceId;
    if (sourceId == null || sourceId.isEmpty || sourceId == 'local') continue;
    groups.putIfAbsent(sourceId, () => []).add(item);
  }
  if (groups.isEmpty) return const [];

  final order = groups.keys.toList()
    ..sort((left, right) {
      final leftIndex = sourceOrder.indexOf(left);
      final rightIndex = sourceOrder.indexOf(right);
      if (leftIndex >= 0 || rightIndex >= 0) {
        if (leftIndex < 0) return 1;
        if (rightIndex < 0) return -1;
        return leftIndex.compareTo(rightIndex);
      }
      return stableHashOf(
        'source:$left',
      ).compareTo(stableHashOf('source:$right'));
    });

  final sections = <DiscoverySection>[];
  for (final sourceId in order) {
    if (sections.length >= 2) break;
    final pool = groups[sourceId]!;
    if (pool.length < 5) continue;
    final health = sourceHealth[sourceId] ?? 0.5;
    if (health < tuning.sourceShelfMinHealth) continue;

    final localSeen = {...seen};
    final selected = RecommendationSelection.take(
      pool,
      limit: 8,
      maxPerArtist: 3,
      maxPerAlbum: 2,
      seen: localSeen,
    );
    if (selected.length < 3) continue;

    seen.addAll(localSeen);
    final reason = RecommendationReason(
      kind: RecommendationReasonKind.source,
      sourceId: sourceId,
      confidence: 1,
    );
    sections.add(
      DiscoverySection(
        kind: DiscoverySectionKind.source,
        reason: reason,
        tracks: RecommendationSelection.tracks(selected, forced: reason),
      ),
    );
  }
  return sections;
}

DiscoverySection? buildFallbackSection({
  required List<RecommendationCandidate> candidates,
  required Set<String> seen,
}) {
  final localSeen = {...seen};
  final selected = RecommendationSelection.take(
    candidates,
    limit: 25,
    maxPerArtist: 3,
    maxPerAlbum: 2,
    seen: localSeen,
  );
  if (selected.isEmpty) return null;

  seen.addAll(localSeen);
  return DiscoverySection(
    kind: DiscoverySectionKind.fallback,
    reason: const RecommendationReason.fallback(),
    tracks: RecommendationSelection.tracks(
      selected,
      forced: const RecommendationReason.fallback(),
    ),
  );
}
