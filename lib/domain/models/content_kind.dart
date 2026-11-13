import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';

/// What a track is, as far as the shell is concerned.
enum ContentKind {
  /// A song or an instrumental piece.
  music,

  /// One episode of a show published by a feed.
  ///
  /// The album of such a track is the show, while the artist is the voice of
  /// one episode: two episodes of one show name different artists, so the
  /// source is the identity that keeps them together.
  podcast,

  /// One chapter of a book, read aloud.
  audiobook,

  /// A station that never ends.
  radio;

  /// Whether the track is a recording of speech rather than music.
  bool get isSpokenWord => this == podcast || this == audiobook;
}

/// The source types that publish shows: episodes of one feed.
const Set<String> podcastSourceTypes = {
  'podcast_rss',
  'podcast_catalog',
  'podcast_apple',
};

/// The source types that publish books.
const Set<String> audiobookSourceTypes = {
  'librivox',
  'audiobookshelf',
};

/// The source types whose tracks are speech.
const Set<String> spokenWordSourceTypes = {
  ...podcastSourceTypes,
  ...audiobookSourceTypes,
};

/// Whether the source of [sourceId] publishes speech.
bool isSpokenWordSource(String? sourceId) {
  if (sourceId == null || sourceId.isEmpty) return false;
  return spokenWordSourceTypes.contains(sourceTypeOfId(sourceId));
}

/// Whether the source of [sourceId] publishes a show of episodes.
bool isPodcastSource(String? sourceId) {
  if (sourceId == null || sourceId.isEmpty) return false;
  return podcastSourceTypes.contains(sourceTypeOfId(sourceId));
}

/// Whether the source of [sourceId] publishes a book.
bool isAudiobookSource(String? sourceId) {
  if (sourceId == null || sourceId.isEmpty) return false;
  return audiobookSourceTypes.contains(sourceTypeOfId(sourceId));
}

/// What a track is, read from its source and its live flag.
///
/// It takes the two fields instead of a [Song] so the data layer can classify
/// a row it never builds a track for. A station wins over its source: the
/// same feed cannot be a podcast episode and a stream at once.
ContentKind contentKindOfSource({
  required String? sourceId,
  bool isLiveStream = false,
}) {
  if (isLiveStream) return ContentKind.radio;
  if (isPodcastSource(sourceId)) return ContentKind.podcast;
  if (isAudiobookSource(sourceId)) return ContentKind.audiobook;
  return ContentKind.music;
}

/// What the track is, read from the track alone.
ContentKind contentKindOf(Song song) => contentKindOfSource(
  sourceId: song.sourceId,
  isLiveStream: song.isLiveStream,
);
