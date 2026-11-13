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

  /// A station or a recording of one.
  ///
  /// A live stream never ends; a recording of a broadcast has a length and a
  /// start, and is read as "recorded" instead of "on air".
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

/// The built-in instances whose content kind their adapter cannot tell.
///
/// One adapter serves several collections of the Internet Archive: the
/// collection decides whether an item is an episode of a show, a chapter of
/// a book or a recording of a broadcast. The id of the instance is the only
/// fact the filter and the facets hold, so the declaration lives here, where
/// both the track and the row can read it.
const Map<String, ContentKind> declaredContentKinds = {
  'archive_podcasts': ContentKind.podcast,
  'independent_audiobooks': ContentKind.audiobook,
  'old_time_radio': ContentKind.radio,
  'radio_recordings': ContentKind.radio,
};

/// The genre tags that mark a local file as a chapter of a book.
const Set<String> audiobookGenreTags = {
  'audiobook',
  'audiobooks',
  'audio book',
  'audio books',
  '有声书',
  '有声读物',
};

/// The genre tags that mark a local file as an episode of a show.
const Set<String> podcastGenreTags = {'podcast', 'podcasts', '播客'};

/// The folder names that hold a book, read aloud.
const Set<String> audiobookFolderNames = {
  'audiobook',
  'audiobooks',
  'audio book',
  'audio books',
  '有声书',
  '有声读物',
  '听书',
};

/// The folder names that hold shows.
const Set<String> podcastFolderNames = {'podcast', 'podcasts', '播客'};

/// Whether the source of [sourceId] publishes speech.
bool isSpokenWordSource(String? sourceId) => kindOfSource(sourceId).isSpokenWord;

/// Whether the source of [sourceId] publishes a show of episodes.
bool isPodcastSource(String? sourceId) =>
    kindOfSource(sourceId) == ContentKind.podcast;

/// Whether the source of [sourceId] publishes a book.
bool isAudiobookSource(String? sourceId) =>
    kindOfSource(sourceId) == ContentKind.audiobook;

/// What a source publishes, from the declaration of its instance or its type.
///
/// It answers music for an unknown source or for the local files: only the
/// track itself says what a local file holds.
ContentKind kindOfSource(String? sourceId) {
  if (sourceId == null || sourceId.isEmpty) return ContentKind.music;
  final declared = declaredContentKinds[sourceId];
  if (declared != null) return declared;
  final type = sourceTypeOfId(sourceId);
  if (podcastSourceTypes.contains(type)) return ContentKind.podcast;
  if (audiobookSourceTypes.contains(type)) return ContentKind.audiobook;
  return ContentKind.music;
}

/// Whether the tracks of [sourceId] are files on this machine.
bool isLocalSource(String? sourceId) =>
    sourceId == null || sourceId.isEmpty || sourceId == 'local';

/// What a track is, read from its source and its live flag.
///
/// It takes the two fields instead of a [Song] so the data layer can classify
/// a row it never builds a track for. A station wins over its source: the
/// same feed cannot be a podcast episode and a stream at once.
ContentKind contentKindOfSource({
  required String? sourceId,
  bool isLiveStream = false,
}) =>
    contentKindOfFields(sourceId: sourceId, isLiveStream: isLiveStream);

/// What a track is, read from every field the library can hand over.
///
/// A declared instance is trusted first; a local file has no source, so its
/// tag, its container and the folder it sits in have to say. The order is
/// the order of confidence: an explicit tag first, an audiobook container
/// next, a folder name last. A length is never guessed from: a long track is
/// still a track.
ContentKind contentKindOfFields({
  required String? sourceId,
  bool isLiveStream = false,
  String? uri,
  String? localPath,
  String? genre,
  Iterable<String>? genres,
}) {
  if (isLiveStream) return ContentKind.radio;
  final declared = sourceId == null ? null : declaredContentKinds[sourceId];
  if (declared != null) return declared;
  if (!isLocalSource(sourceId)) return kindOfSource(sourceId);
  return localContentKindOf(
    path: localPath ?? uri ?? '',
    genre: genre,
    genres: genres,
  );
}

/// What a local file holds, from its tags, its container and its folder.
ContentKind localContentKindOf({
  required String path,
  String? genre,
  Iterable<String>? genres,
}) {
  final tags = <String>{
    ..._tagsOf(genre),
    for (final value in genres ?? const <String>[]) ..._tagsOf(value),
  };
  if (tags.any(audiobookGenreTags.contains)) return ContentKind.audiobook;
  if (tags.any(podcastGenreTags.contains)) return ContentKind.podcast;

  final lower = path.toLowerCase();
  if (lower.endsWith('.m4b')) return ContentKind.audiobook;

  for (final segment in lower.split(RegExp(r'[/\\]'))) {
    if (audiobookFolderNames.contains(segment)) return ContentKind.audiobook;
    if (podcastFolderNames.contains(segment)) return ContentKind.podcast;
  }
  return ContentKind.music;
}

/// What the track is, read from the track alone.
ContentKind contentKindOf(Song song) => contentKindOfFields(
  sourceId: song.sourceId,
  isLiveStream: song.isLiveStream,
  uri: song.uri,
  localPath: song.localPath,
  genre: song.genre,
  genres: song.genres,
);

Iterable<String> _tagsOf(String? raw) sync* {
  if (raw == null) return;
  for (final part in raw.split(RegExp(r'[,;/]'))) {
    final tag = part.trim().toLowerCase();
    if (tag.isNotEmpty) yield tag;
  }
}
