import 'package:tune/core/utils/text_order.dart';
import 'package:tune/domain/models/album_summary.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/domain/models/library_sort.dart';
import 'package:tune/domain/models/show_album.dart';
import 'package:tune/domain/models/song.dart';

/// One album of the library: the songs of the album and the face of it.
///
/// The songs of an album are not always next to each other in the library:
/// a source can answer in whatever order it likes, and the reader can sort
/// or filter the list. The album view groups them again, so an album is one
/// card with one cover instead of a row of tracks that happen to share a
/// name.
class LibraryAlbum {
  /// Stable identity of the album inside the library.
  ///
  /// The name alone is not enough: two artists can publish an album with
  /// the same name, and they are two albums. Tracks without an album all
  /// share one group, so the singles are still reachable.
  final String key;

  /// The name the album carries, empty for the tracks without one.
  final String name;
  final String artist;

  /// The cover of the album, taken from the first track that has one.
  final String? coverPath;
  final String? coverUrl;

  /// The songs of the album, in the order of the album.
  final List<Song> songs;

  /// What the album holds: songs, episodes of a show or chapters of a book.
  final ContentKind kind;

  const LibraryAlbum({
    required this.key,
    required this.name,
    required this.artist,
    required this.songs,
    this.coverPath,
    this.coverUrl,
    this.kind = ContentKind.music,
  });

  int get trackCount => songs.length;

  /// Whether the album is the group of tracks that have no album at all.
  bool get isUnknown => name.isEmpty;

  /// Whether the tracks of the group name more than one artist.
  ///
  /// The singles of one reader can come from everywhere; the card may not
  /// write one artist over all of them.
  bool get hasMultipleArtists {
    final artists = <String>{};
    for (final song in songs) {
      final artist = song.artist.trim().toLowerCase();
      if (artist.isEmpty) continue;
      artists.add(artist);
      if (artists.length > 1) return true;
    }
    return false;
  }

  int get durationInMillis {
    var total = 0;
    for (final song in songs) {
      total += song.durationInMillis;
    }
    return total;
  }
}

/// Groups the tracks of a library into albums.
///
/// The tracks without an album are one group of their own: a library of
/// singles has no album to show, but the reader still has to reach the
/// songs. The albums are ordered by name, and the tracks inside an album by
/// disc and track number, so the album view reads in the order the album
/// was published.
List<LibraryAlbum> libraryAlbumsOf(List<Song> songs) {
  final groups = <String, List<Song>>{};
  final spoken = <Song>[];
  for (final song in songs) {
    final kind = contentKindOf(song);
    // A station is not an album: it never ends, and the names it carries
    // describe the song that happens to air, not the stream itself. A
    // recording of a broadcast is read as a station too, so it stays out.
    if (kind == ContentKind.radio) continue;
    if (kind.isSpokenWord) {
      spoken.add(song);
      continue;
    }
    groups.putIfAbsent(libraryAlbumKeyOf(song), () => []).add(song);
  }
  for (final show in spokenAlbumsOf(spoken)) {
    groups.putIfAbsent(show.key, () => []).addAll(show.songs);
  }

  final albums = <LibraryAlbum>[
    for (final group in groups.entries) _albumOf(group.value, key: group.key),
  ];
  albums.sort((left, right) {
    if (left.name.isEmpty != right.name.isEmpty) {
      return left.name.isEmpty ? 1 : -1;
    }
    final byName = compareText(left.name, right.name);
    if (byName != 0) return byName;
    return compareText(left.artist, right.artist);
  });
  return albums;
}

/// Groups the tracks of a library into the rows of the group list.
///
/// One row is one album of one source: the name and the source decide, not
/// the artist. A compilation names a different performer on every track, so
/// grouping by artist would turn one album into as many rows as it has
/// composers — the reader then sees the same album title repeated down the
/// list, which is the opposite of a group row.
List<LibraryAlbum> libraryAlbumGroupsOf(List<Song> songs) {
  final groups = <String, List<Song>>{};
  final spoken = <Song>[];
  for (final song in songs) {
    final kind = contentKindOf(song);
    if (kind == ContentKind.radio) continue;
    if (kind.isSpokenWord) {
      spoken.add(song);
      continue;
    }
    groups.putIfAbsent(_groupKeyOf(song), () => []).add(song);
  }
  for (final show in spokenAlbumsOf(spoken)) {
    groups.putIfAbsent(show.key, () => []).addAll(show.songs);
  }

  final albums = <LibraryAlbum>[
    for (final group in groups.entries) _groupOf(group.value, key: group.key),
  ];
  albums.sort((left, right) {
    if (left.name.isEmpty != right.name.isEmpty) {
      return left.name.isEmpty ? 1 : -1;
    }
    final byName = compareText(left.name, right.name);
    if (byName != 0) return byName;
    return compareText(left.artist, right.artist);
  });
  return albums;
}

/// Whether the group row of [album] is really one song.
///
/// A music album of one track is not an album the reader can walk into: it is
/// a single. The library list draws it as a track row instead of a group row,
/// and this function is the only place that decides it — the page, the list
/// and the tests all ask here.
///
/// A show or a book of one episode keeps its group row: the row names the
/// show as well as the episode, and the reader still walks into it.
bool isSingleTrackGroup(LibraryAlbum album) =>
    album.kind == ContentKind.music && album.songs.length == 1;

/// One row of the group list.
///
/// The list holds two kinds of rows in one order: a group the reader can
/// open, and the track of a group that has only one track.
sealed class LibraryListRow {
  const LibraryListRow();
}

/// A group row: an album, a show or a book that opens into its tracks.
final class LibraryAlbumRow extends LibraryListRow {
  const LibraryAlbumRow(this.album);

  final LibraryAlbum album;
}

/// A track row: the only track of a one-track group.
final class LibrarySingleRow extends LibraryListRow {
  const LibrarySingleRow(this.song, {required this.index});

  final Song song;

  /// The position of the track in the list the page was given.
  ///
  /// The track row keeps the table's number column, so it has to say which
  /// track of the list it is, not which row of the mixed list.
  final int index;
}

/// The rows of the group list, in the order of [sort].
///
/// A group with one track becomes that track's row; every other group stays
/// one row. Both kinds are ranked by the column the sort names, read from
/// what the row itself writes: the group name, its artist, its newest track
/// and its total length for a group, and the track's own facts for a single.
/// A tie falls back to the row name, so the list does not jump between
/// rebuilds when the sort column is equal.
List<LibraryListRow> libraryRowsOf(
  List<Song> songs, {
  required LibrarySort sort,
}) {
  final indexOf = <String, int>{
    for (var i = 0; i < songs.length; i++) songs[i].uri: i,
  };
  final rows = <LibraryListRow>[];
  for (final album in libraryAlbumGroupsOf(songs)) {
    if (isSingleTrackGroup(album)) {
      final song = album.songs.single;
      rows.add(LibrarySingleRow(song, index: indexOf[song.uri] ?? rows.length));
    } else {
      rows.add(LibraryAlbumRow(album));
    }
  }
  rows.sort((left, right) => _compareRows(left, right, sort));
  return rows;
}

int _compareRows(LibraryListRow left, LibraryListRow right, LibrarySort sort) {
  final order = _compareByField(left, right, sort.field);
  if (order != 0) return sort.ascending ? order : -order;
  final byName = _compareTextLastEmpty(_rowName(left), _rowName(right));
  if (byName != 0) return byName;
  return _compareTextLastEmpty(_rowId(left), _rowId(right));
}

int _compareByField(
  LibraryListRow left,
  LibraryListRow right,
  LibrarySortField field,
) {
  switch (field) {
    case LibrarySortField.title:
      return _compareTextLastEmpty(_rowTitle(left), _rowTitle(right));
    case LibrarySortField.album:
      return _compareTextLastEmpty(_rowAlbum(left), _rowAlbum(right));
    case LibrarySortField.artist:
      return _compareTextLastEmpty(_rowArtist(left), _rowArtist(right));
    case LibrarySortField.addedAt:
      return _rowAddedAt(left).compareTo(_rowAddedAt(right));
    case LibrarySortField.duration:
      return _rowDuration(left).compareTo(_rowDuration(right));
  }
}

/// Compares two names, with the empty one last.
///
/// The group list has always kept the tracks without an album at the bottom;
/// a single with no title belongs there too.
int _compareTextLastEmpty(String left, String right) {
  if (left.isEmpty != right.isEmpty) return left.isEmpty ? 1 : -1;
  return compareText(left, right);
}

String _rowTitle(LibraryListRow row) => switch (row) {
  LibraryAlbumRow(:final album) => album.name,
  LibrarySingleRow(:final song) => song.title.trim(),
};

String _rowName(LibraryListRow row) => switch (row) {
  LibraryAlbumRow(:final album) => album.name,
  LibrarySingleRow(:final song) =>
    song.title.trim().isEmpty ? song.album.trim() : song.title.trim(),
};

String _rowAlbum(LibraryListRow row) => switch (row) {
  LibraryAlbumRow(:final album) => album.name,
  LibrarySingleRow(:final song) => song.album.trim(),
};

String _rowArtist(LibraryListRow row) => switch (row) {
  LibraryAlbumRow(:final album) =>
    album.artist.isNotEmpty ? album.artist : album.songs.first.artist.trim(),
  LibrarySingleRow(:final song) => song.artist.trim(),
};

int _rowAddedAt(LibraryListRow row) => switch (row) {
  LibraryAlbumRow(:final album) => album.songs.fold(
    0,
    (latest, song) => song.dateAdded > latest ? song.dateAdded : latest,
  ),
  LibrarySingleRow(:final song) => song.dateAdded,
};

int _rowDuration(LibraryListRow row) => switch (row) {
  LibraryAlbumRow(:final album) => album.durationInMillis,
  LibrarySingleRow(:final song) => song.durationInMillis,
};

String _rowId(LibraryListRow row) => switch (row) {
  LibraryAlbumRow(:final album) => album.key,
  LibrarySingleRow(:final song) => song.uri,
};

/// The key a group row is grouped by: the album name and where it came from.
String _groupKeyOf(Song song) {
  final name = normalizedAlbumName(song.album);
  final source = song.sourceId ?? 'local';
  return '$name\u0000$source';
}

/// Builds one group row out of its tracks.
LibraryAlbum _groupOf(List<Song> songs, {required String key}) {
  final artists = <String>{};
  for (final song in songs) {
    final artist = song.artist.trim();
    if (artist.isNotEmpty) artists.add(artist);
  }
  final album = _albumOf(songs, key: key);
  return LibraryAlbum(
    key: key,
    name: album.name,
    artist: artists.length == 1 ? artists.single : '',
    coverPath: album.coverPath,
    coverUrl: album.coverUrl,
    songs: album.songs,
    kind: album.kind,
  );
}

/// The group row of [songs] that holds [song], if the list has one.
LibraryAlbum? libraryGroupOf(Iterable<Song> songs, Song song) {
  for (final group in libraryAlbumGroupsOf(songs.toList())) {
    for (final track in group.songs) {
      if (track.uri == song.uri) return group;
    }
  }
  return null;
}

/// The key the album of [song] is grouped by.
///
/// The library view uses it to tell which album holds the track that plays,
/// and the grouping uses it to keep the tracks of one album together.
String libraryAlbumKeyOf(Song song) {
  return albumKeyOf(
    album: song.album,
    artist: song.artist,
    sourceId: song.sourceId,
  );
}

/// The row of the group list that holds [song], if the list has one.
///
/// A music track names its album and artist. A show the library merged from
/// several sources carries a key that names every source, so an episode lands
/// on that card when the show name matches and its source is one of them.
/// Both the album column and the "playing" marker read this one rule.
AlbumSummary? albumSummaryOf(List<AlbumSummary> albums, Song song) {
  final ownKey = libraryAlbumKeyOf(song);
  for (final album in albums) {
    if (album.key == ownKey) return album;
  }
  if (!contentKindOf(song).isSpokenWord) return null;
  final name = normalizedShowNameOf(song.album);
  final source = song.sourceId ?? 'local';
  for (final album in albums) {
    if (!isMergedShowKey(album.key)) continue;
    final parts = album.key.split('\u0000');
    if (parts.first != name) continue;
    final sources = [for (final part in parts.skip(2)) ...part.split('\u0001')];
    if (sources.contains(source)) return album;
  }
  return null;
}

/// Whether an artwork URL is a cover rather than a site icon.
///
/// Radio rows carry the station's `favicon.ico`; upscaled into a 40 px square
/// it is a bright patch of colour that belongs to no album, so a group skips
/// it and falls back to the quiet placeholder instead.
bool _isCoverArt(String url) {
  final last = url.split('/').last.toLowerCase();
  if (last.isEmpty || last.startsWith('favicon')) return false;
  return !last.contains('favicon.');
}

LibraryAlbum _albumOf(List<Song> songs, {String? key}) {
  final ordered = List<Song>.of(songs)..sort(albumOrderOf);
  final first = ordered.first;

  String? coverPath;
  String? coverUrl;
  for (final song in ordered) {
    // A row whose artwork is a site icon has a cached copy on disk too, so the
    // URL is what decides: without that check an already-cached favicon keeps
    // winning the group even after the source stops handing it over.
    final url = song.artworkUrl;
    final isIcon = url != null && url.isNotEmpty && !_isCoverArt(url);
    if (isIcon) continue;
    final path = song.albumArtPath;
    if (coverPath == null && path != null && path.isNotEmpty) {
      coverPath = path;
    }
    if (coverUrl == null && url != null && url.isNotEmpty) {
      coverUrl = url;
    }
    if (coverPath != null && coverUrl != null) break;
  }

  return LibraryAlbum(
    key: key ?? libraryAlbumKeyOf(first),
    name: first.album.trim(),
    artist: first.artist.trim(),
    kind: contentKindOf(first),
    coverPath: coverPath,
    coverUrl: coverUrl,
    songs: List.unmodifiable(ordered),
  );
}
