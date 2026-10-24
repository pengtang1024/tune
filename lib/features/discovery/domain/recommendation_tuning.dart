/// The weights of one recommendation.
///
/// The numbers are kept in one place so a change can be read, tested and
/// compared with the performance budget instead of being spread through the
/// scoring functions. The base weights add up to one; the favorite boost and
/// the penalties are applied after the base score and the result is clamped
/// to 0..1.
class RecommendationTuning {
  final double artistWeight;
  final double genreWeight;
  final double eraWeight;
  final double albumWeight;
  final double qualityWeight;
  final double noveltyWeight;
  final double freshnessWeight;

  /// Added when the track is already marked with a heart.
  final double favoriteBoost;

  /// How much a track played in the last [recentDays] is pushed down.
  final double recentPenalty;

  /// How much a track with a high skip share is pushed down.
  final double skipPenalty;

  /// The half-life of a skip: an old skip matters less than a recent one.
  final int skipHalfLifeDays;

  /// How much a track already in the queue is pushed down.
  final double queuePenalty;

  /// How much the health of a source can lower a track's score.
  ///
  /// This consumes the score produced by the source health system; it is not
  /// a second copy of that system's dimension weights.
  final double sourceHealthWeight;

  /// The lowest health a source needs before its own shelf is shown.
  final double sourceShelfMinHealth;

  /// The most tracks one artist may occupy across the whole page.
  final int artistPageBudget;

  /// How much a track without a cover is pushed down.
  ///
  /// This is a penalty rather than a base weight: the card is mostly cover,
  /// so a missing one should never make a track win a tie, but taste signals
  /// can still lift it when nothing better is available.
  final double artworkPenalty;

  final int dailyMixSize;
  final int favoriteAnchors;
  final int explorationSlots;
  final int adjacentSlots;
  final int artistShelfMinTracks;

  /// A track played less than this many days ago feels recent.
  final int recentDays;

  const RecommendationTuning({
    this.artistWeight = 0.30,
    this.genreWeight = 0.22,
    this.eraWeight = 0.10,
    this.albumWeight = 0.05,
    this.qualityWeight = 0.18,
    this.noveltyWeight = 0.10,
    this.freshnessWeight = 0.05,
    this.favoriteBoost = 0.10,
    this.recentPenalty = 0.35,
    this.skipPenalty = 0.30,
    this.skipHalfLifeDays = 90,
    this.queuePenalty = 0.20,
    this.sourceHealthWeight = 0.20,
    this.sourceShelfMinHealth = 0.60,
    this.artistPageBudget = 10,
    this.artworkPenalty = 0.10,
    this.dailyMixSize = 25,
    this.favoriteAnchors = 2,
    this.explorationSlots = 3,
    this.adjacentSlots = 3,
    this.artistShelfMinTracks = 3,
    this.recentDays = 30,
  });

  static const defaults = RecommendationTuning();
}
