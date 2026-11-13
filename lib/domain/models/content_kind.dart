import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';

/// What a track is, as far as the shell is concerned.
enum ContentKind {
  /// A song or an instrumental piece.
  music,

  /// A podcast episode, an audiobook chapter or another recording of speech.
  ///
  /// The album of such a track is the show or the book, while the artist is
  /// the voice of one episode: two episodes of one show name different
  /// artists, so the source is the identity that keeps them together.
  spokenWord,

  /// A station that never ends.
  radio,
}

/// The source types whose tracks are speech.
const Set<String> spokenWordSourceTypes = {
  'podcast_rss',
  'podcast_catalog',
  'podcast_apple',
  'librivox',
  'audiobookshelf',
};

/// Whether the source of [sourceId] publishes speech.
bool isSpokenWordSource(String? sourceId) {
  if (sourceId == null || sourceId.isEmpty) return false;
  return spokenWordSourceTypes.contains(sourceTypeOfId(sourceId));
}

/// What the track is, read from the track alone.
ContentKind contentKindOf(Song song) {
  if (song.isLiveStream) return ContentKind.radio;
  if (isSpokenWordSource(song.sourceId)) return ContentKind.spokenWord;
  return ContentKind.music;
}
