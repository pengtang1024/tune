/// Why a track is on the discover page.
///
/// The reason is data, not a sentence: the interface writes it in the
/// language of the reader. A track that has no reason the app can name falls
/// back to the plain "picked from your library" reason instead of inventing
/// one.
enum RecommendationReasonKind {
  favorite,
  artist,
  genre,
  era,
  adjacent,
  fresh,
  unheard,
  source,
  fallback,
}

class RecommendationReason {
  final RecommendationReasonKind kind;

  /// The artist the track is recommended for, when [kind] is artist.
  final String? artist;

  /// The normalized genre, when [kind] is genre.
  final String? genre;

  /// The decade (for example 2000), when [kind] is era.
  final int? decade;

  /// The source instance, when [kind] is source.
  final String? sourceId;

  /// How strongly the reason contributed, between 0 and 1.
  final double confidence;

  const RecommendationReason({
    required this.kind,
    this.artist,
    this.genre,
    this.decade,
    this.sourceId,
    this.confidence = 0,
  });

  const RecommendationReason.favorite()
    : kind = RecommendationReasonKind.favorite,
      artist = null,
      genre = null,
      decade = null,
      sourceId = null,
      confidence = 1;

  const RecommendationReason.fresh()
    : kind = RecommendationReasonKind.fresh,
      artist = null,
      genre = null,
      decade = null,
      sourceId = null,
      confidence = 1;

  const RecommendationReason.fallback()
    : kind = RecommendationReasonKind.fallback,
      artist = null,
      genre = null,
      decade = null,
      sourceId = null,
      confidence = 0;

  @override
  String toString() {
    return 'RecommendationReason(${kind.name}, artist: $artist, '
        'genre: $genre, decade: $decade, sourceId: $sourceId)';
  }
}
