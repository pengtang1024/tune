import 'package:tune/core/utils/text_order.dart';
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

  const LibraryAlbum({
    required this.key,
    required this.name,
    required this.artist,
    required this.songs,
    this.coverPath,
    this.coverUrl,
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
  for (final song in songs) {
    groups.putIfAbsent(libraryAlbumKeyOf(song), () => []).add(song);
  }

  final albums = <LibraryAlbum>[
    for (final group in groups.values) _albumOf(group),
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
  final album = song.album.trim().toLowerCase();
  if (album.isEmpty) return '\u0000unknown';
  return '$album\u0000${song.artist.trim().toLowerCase()}';
}

LibraryAlbum _albumOf(List<Song> songs) {
  final ordered = List<Song>.of(songs)..sort(_byAlbumOrder);
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
    key: libraryAlbumKeyOf(first),
    name: first.album.trim(),
    artist: first.artist.trim(),
    coverPath: coverPath,
    coverUrl: coverUrl,
    songs: List.unmodifiable(ordered),
  );
}

int _byAlbumOrder(Song left, Song right) {
  final disc = (left.discNumber ?? 1).compareTo(right.discNumber ?? 1);
  if (disc != 0) return disc;
  final track = (left.trackNumber ?? 0).compareTo(right.trackNumber ?? 0);
  if (track != 0) return track;
  return compareText(left.title, right.title);
}
