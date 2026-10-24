import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/recommendation_reason.dart';

/// A track of the discover page and the reason it is there.
class RecommendedTrack {
  final Song song;
  final double score;
  final RecommendationReason reason;

  /// Whether the track was already marked when the page was built.
  final bool fromFavorites;

  const RecommendedTrack({
    required this.song,
    required this.score,
    required this.reason,
    required this.fromFavorites,
  });
}
