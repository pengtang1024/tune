import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/discovery/domain/recommendation_candidate.dart';
import 'package:tune/features/discovery/domain/recommendation_daily_mix.dart';
import 'package:tune/features/discovery/domain/recommendation_explore_section.dart';
import 'package:tune/features/discovery/domain/recommendation_extra_sections.dart';
import 'package:tune/features/discovery/domain/recommendation_favorite_artists.dart';
import 'package:tune/features/discovery/domain/recommendation_scoring.dart';
import 'package:tune/features/discovery/domain/recommended_track.dart';
import 'package:tune/features/discovery/domain/recommendation_tuning.dart';
import 'package:tune/features/discovery/domain/track_listening.dart';
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
  const RecommendationEngine({this.tuning = RecommendationTuning.defaults});

  final RecommendationTuning tuning;

  DiscoveryOutput recommend({
    required List<Song> library,
    required Set<String> favoriteUris,
    required TasteProfile profile,
    required Set<String> dismissedUris,
    Set<String> dismissedArtists = const {},
    Set<String> queuedUris = const {},
    Map<String, double> sourceHealth = const {},
    required List<String> sourceOrder,
    required String dateKey,
    Map<String, TrackListening> listening = const {},
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
      dismissedArtists: dismissedArtists,
      queuedUris: queuedUris,
      listening: listening,
    );
    scoreCandidates(
      candidates,
      profile: profile,
      allowFresh: allowFresh,
      now: clock,
      sourceHealth: sourceHealth,
      tuning: tuning,
    );
    // The queue is what the reader is already about to hear. Push its tracks
    // down instead of hiding them: a queue that happens to hold the whole
    // library must not leave an empty page.
    for (final candidate in candidates) {
      if (!candidate.queued) continue;
      candidate.score = (candidate.score - tuning.queuePenalty)
          .clamp(0.0, 1.0)
          .toDouble();
    }
    for (final candidate in candidates) {
      candidate.tieBreak = stableHashOf('${candidate.uri}|$seed');
    }
    final sorted = RecommendationSelection.sortByScore(candidates);

    final seen = <String>{};
    final sections = <DiscoverySection>[];

    final daily = buildDailyMix(
      candidates: sorted,
      profile: profile,
      tuning: tuning,
      seed: seed,
      seen: seen,
    );
    if (daily != null) sections.add(daily);

    sections.addAll(
      buildArtistSections(
        candidates: sorted,
        profile: profile,
        tuning: tuning,
        seen: seen,
      ),
    );

    final favoriteArtists = buildFavoriteArtistSection(
      candidates: sorted,
      profile: profile,
      seen: seen,
    );
    if (favoriteArtists != null) sections.add(favoriteArtists);

    final fresh = buildFreshSection(
      candidates: sorted,
      allowFresh: allowFresh,
      now: clock,
      seen: seen,
    );
    if (fresh != null) sections.add(fresh);

    final explore = buildExploreSection(
      candidates: sorted,
      profile: profile,
      seen: seen,
    );
    if (explore != null) sections.add(explore);

    sections.addAll(
      buildSourceSections(
        candidates: sorted,
        sourceOrder: sourceOrder,
        sourceHealth: sourceHealth,
        tuning: tuning,
        seen: seen,
      ),
    );

    if (sections.isEmpty) {
      final fallback = buildFallbackSection(candidates: sorted, seen: seen);
      if (fallback != null) sections.add(fallback);
    }

    return DiscoveryOutput(
      sections: List.unmodifiable(
        _limitArtistPage(sections, tuning.artistPageBudget),
      ),
    );
  }
}

List<DiscoverySection> _limitArtistPage(
  List<DiscoverySection> sections,
  int budget,
) {
  if (budget <= 0) return sections;
  final counts = <String, int>{};
  final result = <DiscoverySection>[];
  for (final section in sections) {
    final tracks = <RecommendedTrack>[];
    for (final track in section.tracks) {
      final artist = normalizeTasteKey(track.song.artist);
      if (artist.isNotEmpty) {
        final count = counts[artist] ?? 0;
        if (count >= budget) continue;
        counts[artist] = count + 1;
      }
      tracks.add(track);
    }
    if (tracks.isEmpty) continue;
    result.add(
      DiscoverySection(
        kind: section.kind,
        reason: section.reason,
        tracks: List.unmodifiable(tracks),
      ),
    );
  }
  return result;
}
