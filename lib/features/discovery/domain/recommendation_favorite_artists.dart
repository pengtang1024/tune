import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/discovery/domain/recommendation_candidate.dart';
import 'package:tune/features/discovery/domain/recommendation_reason.dart';
import 'package:tune/features/discovery/domain/recommendation_selection.dart';
import 'package:tune/features/discovery/domain/taste_profile.dart';

/// A mixed shelf for the favorite artists that cannot fill a shelf alone.
///
/// A shelf per artist needs at least three unheard tracks. A reader with one
/// or two tracks from several artists would otherwise get no artist section
/// at all; this shelf gathers those small remainders into one row.
DiscoverySection? buildFavoriteArtistSection({
  required List<RecommendationCandidate> candidates,
  required TasteProfile profile,
  required Set<String> seen,
}) {
  if (profile.artists.isEmpty) return null;

  final soloArtists = profile.topArtists(2).toSet();
  final pool = candidates
      .where(
        (item) =>
            !item.favorite &&
            item.artistKey.isNotEmpty &&
            !soloArtists.contains(item.artistKey) &&
            profile.artistWeightKey(item.artistKey) > 0,
      )
      .toList(growable: false);
  if (pool.length < 3) return null;

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
  return DiscoverySection(
    kind: DiscoverySectionKind.favoriteArtists,
    reason: const RecommendationReason.fallback(),
    tracks: RecommendationSelection.tracks(selected),
  );
}
