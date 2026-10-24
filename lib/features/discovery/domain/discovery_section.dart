import 'package:tune/features/discovery/domain/recommendation_reason.dart';
import 'package:tune/features/discovery/domain/recommended_track.dart';

/// The kinds of rows the discover page shows, in the order they appear.
enum DiscoverySectionKind {
  dailyMix,
  artist,
  favoriteArtists,
  explore,
  fresh,
  source,
  onlineArtist,
  fallback,
}

class DiscoverySection {
  final DiscoverySectionKind kind;
  final RecommendationReason reason;
  final List<RecommendedTrack> tracks;

  const DiscoverySection({
    required this.kind,
    required this.reason,
    required this.tracks,
  });

  int get length => tracks.length;
  bool get isEmpty => tracks.isEmpty;
}
