import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/discovery/domain/recommendation_candidate.dart';
import 'package:tune/features/discovery/domain/recommendation_daily_mix.dart';
import 'package:tune/features/discovery/domain/recommendation_explore_section.dart';
import 'package:tune/features/discovery/domain/recommendation_extra_sections.dart';
import 'package:tune/features/discovery/domain/recommendation_scoring.dart';
import 'package:tune/features/discovery/domain/recommendation_selection.dart';
import 'package:tune/features/discovery/domain/taste_profile.dart';

/// The sections of one visit to the discover page.
class DiscoveryOutput {
  final List<DiscoverySection> sections;

  const DiscoveryOutput({this.sections = const []});
}

/// Builds the discover page from the library and the favorites.
///
/// The engine is synchronous and has no I/O: the same inputs and the same day
/// give the same sections, which keeps the page from reshuffling under the
/// reader every time the library is read again.
class RecommendationEngine {
  const RecommendationEngine();

  DiscoveryOutput recommend({
    required List<Song> library,
    required Set<String> favoriteUris,
    required TasteProfile profile,
    required Set<String> dismissedUris,
    required List<String> sourceOrder,
    required String dateKey,
    int refreshSalt = 0,
    bool allowFresh = false,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final seed = stableHashOf(
      '$dateKey|$refreshSalt|${library.length}|${profile.signature}',
    );
    final candidates = buildCandidates(
      library: library,
      favoriteUris: favoriteUris,
      dismissedUris: dismissedUris,
    );
    scoreCandidates(
      candidates,
      profile: profile,
      allowFresh: allowFresh,
      now: clock,
    );
    for (final candidate in candidates) {
      candidate.tieBreak = stableHashOf('${candidate.uri}|$seed');
    }
    final sorted = RecommendationSelection.sortByScore(candidates);

    final seen = <String>{};
    final sections = <DiscoverySection>[];

    final daily = buildDailyMix(
      candidates: sorted,
      profile: profile,
      seed: seed,
      seen: seen,
    );
    if (daily != null) sections.add(daily);

    sections.addAll(
      buildArtistSections(candidates: sorted, profile: profile, seen: seen),
    );

    final explore = buildExploreSection(
      candidates: sorted,
      profile: profile,
      seen: seen,
    );
    if (explore != null) sections.add(explore);

    final fresh = buildFreshSection(
      candidates: sorted,
      allowFresh: allowFresh,
      now: clock,
      seen: seen,
    );
    if (fresh != null) sections.add(fresh);

    sections.addAll(
      buildSourceSections(
        candidates: sorted,
        sourceOrder: sourceOrder,
        seen: seen,
      ),
    );

    if (sections.isEmpty) {
      final fallback = buildFallbackSection(candidates: sorted, seen: seen);
      if (fallback != null) sections.add(fallback);
    }

    return DiscoveryOutput(sections: List.unmodifiable(sections));
  }
}
