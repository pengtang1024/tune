import 'package:tune/core/utils/text_order.dart';
import 'package:tune/domain/models/album_summary.dart';
import 'package:tune/domain/models/content_kind.dart';
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
      artists.add(song.artist.trim().toLowerCase());
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

LibraryAlbum _albumOf(List<Song> songs, {String? key}) {
  final ordered = List<Song>.of(songs)..sort(albumOrderOf);
  final first = ordered.first;

  String? coverPath;
  String? coverUrl;
  for (final song in ordered) {
    final path = song.albumArtPath;
    if (coverPath == null && path != null && path.isNotEmpty) {
      coverPath = path;
    }
    final url = song.artworkUrl;
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
