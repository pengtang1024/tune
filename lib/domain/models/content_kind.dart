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
  radio,

  /// A sound effect or a field recording: audio that is neither a song nor
  /// speech.
  ///
  /// The source itself says so with its genre tags; a library that holds
  /// several hundred of them would otherwise read as a shelf of very short
  /// songs.
  soundEffect;

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
  'foreign_audio': ContentKind.audiobook,
  'independent_audiobooks': ContentKind.audiobook,
  'news_recordings': ContentKind.radio,
  'old_time_radio': ContentKind.radio,
  'poetry': ContentKind.audiobook,
  'poetry_books': ContentKind.audiobook,
  'radio_recordings': ContentKind.radio,
  'science_talks': ContentKind.podcast,
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

/// The prefix of the genre tags that mark audio as neither music nor speech.
///
/// The Internet Archive files sound effects, field recordings and other
/// non-music audio under its own "Non-Music" genre; no length or title is
/// ever read to guess this, because a song can be one second long too.
const String nonMusicGenrePrefix = 'non-music';

/// The albums whose kind the instance cannot tell.
///
/// A collection can hold one item that is a play and a hundred that are
/// songs. The item is the album: the name of the album is the only fact that
/// splits them without guessing, so the exception is written here, together
/// with the instance it belongs to. Names are normalized with
/// [normalizedAlbumName]. An album exception also refines a declared
/// instance: the declaration describes the collection, the album names the
/// one item that was filed under the wrong shelf.
const Map<String, Map<String, ContentKind>> declaredAlbumKinds = {
  'archive_podcasts': {
    // A show of old-time radio, a piano record and a sleep-music record were
    // uploaded into the podcast collection; the item names say what they are.
    'piano': ContentKind.music,
    'relicradio.com': ContentKind.radio,
    'sleep safe & calm beat insomnia. peaceful music for deep sleep. delta waves':
        ContentKind.music,
  },
  'community_world': {
    // Two items of a world-music collection are books uploaded with the
    // uploader's own "Full Audiobook" / "Unabridged Audiobook" item title;
    // their genre tag still says World, so the album name is the only
    // declaration that names them.
    "alice's adventures in wonderland full audiobook": ContentKind.audiobook,
    'around the world in eighty days unabridged audiobook jules verne':
        ContentKind.audiobook,
  },
  'unlocked_recordings': {
    'death of a salesman': ContentKind.audiobook,
  },
  'community_classical': {
    // A pack of one- to three-second tabla loops for composing was uploaded
    // into the classical collection; every track is a bar of a beat, not a
    // piece of music to listen to.
    'tabla loops for music composition - 8 beats kaharwa taal':
        ContentKind.soundEffect,
  },
};

/// The genre tags that name speech outright, whatever the instance declares.
///
/// Only these tags may overrule an instance: a plain music genre never can,
/// so `radio_recordings` keeps its broadcasts even when one item says Blues.
/// The leading tag of a genre string is the one read, exactly as the SQL
/// predicate reads it. Speech and comedy have no home of their own among the
/// five kinds, so they read as a spoken programme.
const Map<String, ContentKind> spokenGenrePrefixes = {
  'audiobook': ContentKind.audiobook,
  'audio book': ContentKind.audiobook,
  'books and spoken': ContentKind.audiobook,
  'books & spoken': ContentKind.audiobook,
  'poetry': ContentKind.audiobook,
  'speech': ContentKind.podcast,
  'comedy': ContentKind.podcast,
};

/// The collections the Internet Archive files an item under, and what each
/// one says the item is.
///
/// An item carries its own `collection` array. That is the archive's own
/// declaration, so reading it at scan time is not a guess: it is the fact the
/// per-instance table would otherwise have to repeat by hand.
const Map<String, ContentKind> internetArchiveCollectionKinds = {
  'audio_foreign': ContentKind.audiobook,
  'librivox': ContentKind.audiobook,
  'oldtimeradio': ContentKind.radio,
  'podcasts': ContentKind.podcast,
};

/// The kind the collections of an archive item declare, if any.
ContentKind? contentKindOfCollections(Iterable<String> collections) {
  for (final raw in collections) {
    final kind = internetArchiveCollectionKinds[raw.trim().toLowerCase()];
    if (kind != null) return kind;
  }
  return null;
}

/// The kind an item states for itself, written as [ContentKind.name].
///
/// The Internet Archive adapter writes it beside the track it read, so a row
/// the filter sees carries the archive's own word instead of the whole
/// instance's word.
ContentKind? statedContentKind(String? name) {
  if (name == null || name.isEmpty) return null;
  for (final kind in ContentKind.values) {
    if (kind.name == name) return kind;
  }
  return null;
}

/// The album name as the album exceptions write it.
String normalizedAlbumName(String? album) =>
    (album ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

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
/// A word the source wrote about this one item is trusted first, then a
/// spoken genre tag, then the album exception, then the instance. A local
/// file has no source, so its tag, its container and the folder it sits in
/// have to say. The order is the order of confidence: an explicit tag first,
/// an audiobook container next, a folder name last. A length is never guessed
/// from: a long track is still a track.
ContentKind contentKindOfFields({
  required String? sourceId,
  bool isLiveStream = false,
  String? uri,
  String? localPath,
  String? album,
  String? genre,
  Iterable<String>? genres,
  String? statedKind,
}) {
  if (isLiveStream) return ContentKind.radio;
  final stated = statedContentKind(statedKind);
  if (stated != null) return stated;
  final spoken = _spokenGenreKind(genre, genres);
  if (spoken != null) return spoken;
  final byAlbum = _albumExceptionOf(sourceId, album);
  if (byAlbum != null) return byAlbum;
  final declared = sourceId == null ? null : declaredContentKinds[sourceId];
  if (declared != null) return declared;
  if (_isNonMusic(genre, genres)) return ContentKind.soundEffect;
  if (!isLocalSource(sourceId)) return kindOfSource(sourceId);
  return localContentKindOf(
    path: localPath ?? uri ?? '',
    genre: genre,
    genres: genres,
  );
}

/// The kind an album exception gives, for any instance.
ContentKind? _albumExceptionOf(String? sourceId, String? album) {
  if (sourceId == null || album == null || album.trim().isEmpty) return null;
  return declaredAlbumKinds[sourceId]?[normalizedAlbumName(album)];
}

/// The kind a spoken genre tag names, read from the leading tag only.
ContentKind? _spokenGenreKind(String? genre, Iterable<String>? genres) {
  for (final raw in [genre, ...?genres]) {
    for (final tag in _tagsOf(raw)) {
      for (final entry in spokenGenrePrefixes.entries) {
        if (tag.startsWith(entry.key)) return entry.value;
      }
      // Only the first tag of a string is read, as the SQL predicate does.
      break;
    }
  }
  return null;
}

/// Whether the tags of the track name audio that is not music.
bool _isNonMusic(String? genre, Iterable<String>? genres) {
  for (final raw in [genre, ...?genres]) {
    for (final tag in _tagsOf(raw)) {
      if (tag.startsWith(nonMusicGenrePrefix)) return true;
    }
  }
  return false;
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
  album: song.album,
  genre: song.genre,
  genres: song.genres,
  statedKind: song.sourceData?['contentKind']?.toString(),
);

Iterable<String> _tagsOf(String? raw) sync* {
  if (raw == null) return;
  for (final part in raw.split(RegExp(r'[,;/]'))) {
    final tag = part.trim().toLowerCase();
    if (tag.isNotEmpty) yield tag;
  }
}
