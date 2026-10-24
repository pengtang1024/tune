import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/recommendation_reason.dart';
import 'package:tune/features/discovery/domain/taste_profile.dart';
import 'package:tune/features/discovery/domain/track_listening.dart';

/// A track of the library while the page is being built.
class RecommendationCandidate {
  final Song song;
  final String artistKey;
  final Map<String, String> genres;
  final String albumKey;
  final int? decade;
  final bool favorite;
  final TrackListening listening;

  double score = 0;
  double quality = 0;
  double novelty = 0;
  double recentPenalty = 0;
  double skipPenalty = 0;
  int tieBreak = 0;
  RecommendationReason reason = const RecommendationReason.fallback();

  RecommendationCandidate({
    required this.song,
    required this.artistKey,
    required this.genres,
    required this.albumKey,
    required this.decade,
    required this.favorite,
    required this.listening,
  });

  String get uri => song.uri;
}

/// Builds the candidates of one page.
///
/// A live stream has no end and no fixed length, so it has no place in a
/// recommendation. A track the reader dismissed is left out until the mark
/// expires. The library already merges the copy of a track with its source,
/// so the uri is the only dedupe key used here.
List<RecommendationCandidate> buildCandidates({
  required List<Song> library,
  required Set<String> favoriteUris,
  required Set<String> dismissedUris,
  Map<String, TrackListening> listening = const {},
}) {
  final result = <RecommendationCandidate>[];
  final seen = <String>{};
  for (final song in library) {
    if (song.uri.isEmpty || song.isLiveStream) continue;
    if (dismissedUris.contains(song.uri)) continue;
    if (!seen.add(song.uri)) continue;

    final genres = <String, String>{};
    for (final value in genreValuesOf(song)) {
      genres.putIfAbsent(normalizeTasteKey(value), () => value);
    }
    result.add(
      RecommendationCandidate(
        song: song,
        artistKey: normalizeTasteKey(song.artist),
        genres: genres,
        albumKey: normalizeTasteKey(song.album),
        decade: decadeOf(song.year),
        favorite: favoriteUris.contains(song.uri),
        listening: listening[song.uri] ?? const TrackListening(),
      ),
    );
  }
  return result;
}
