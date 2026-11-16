import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';

/// One collection of the library: everything one instance brought in.
///
/// A collection is not a value of a category. A category narrows the table
/// to the tracks that share a value; a collection is opened, and what it
/// holds is its items, and only then their tracks. That is how the archives
/// it comes from are read, and it keeps a shelf of a thousand one-second
/// uploads from standing in the same list as the songs a reader owns.
class LibraryCollection {
  /// The id of the instance that holds the tracks.
  final String sourceId;

  /// The name a reader knows that instance by.
  final String name;

  /// How many tracks the collection brought in.
  final int trackCount;

  /// How many items (albums, shows, books) those tracks belong to.
  final int itemCount;

  /// A cover taken from the first item that has one, for the card.
  final String? artPath;
  final String? artUrl;

  const LibraryCollection({
    required this.sourceId,
    required this.name,
    required this.trackCount,
    required this.itemCount,
    this.artPath,
    this.artUrl,
  });

  /// The identity of the collection: its instance.
  String get key => sourceId;

  /// Whether the collection has anything to open.
  bool get isEmpty => trackCount == 0;
}

/// The collections the given tracks belong to, largest first.
///
/// The label of an instance is the one the sources page shows; a track whose
/// instance is gone (a removed custom source) keeps its rows and is named by
/// its id rather than dropped from a shelf it is still in.
List<LibraryCollection> libraryCollectionsOf(
  Iterable<Song> songs,
  Map<String, SourceLabel> labels,
) {
  final tracks = <String, int>{};
  final items = <String, Set<String>>{};
  final artPath = <String, String>{};
  final artUrl = <String, String>{};

  for (final song in songs) {
    final id = song.sourceId ?? 'local';
    tracks[id] = (tracks[id] ?? 0) + 1;
    final album = song.album.trim();
    final item = album.isNotEmpty
        ? album.toLowerCase()
        : song.title.trim().toLowerCase();
    (items[id] ??= <String>{}).add(item);
    final path = song.albumArtPath;
    if (path != null && path.isNotEmpty) {
      artPath[id] ??= path;
    }
    final url = song.artworkUrl;
    if (url != null && url.isNotEmpty) {
      artUrl[id] ??= url;
    }
  }

  final collections = [
    for (final entry in tracks.entries)
      LibraryCollection(
        sourceId: entry.key,
        name: _nameOf(entry.key, labels),
        trackCount: entry.value,
        itemCount: items[entry.key]?.length ?? 0,
        artPath: artPath[entry.key],
        artUrl: artUrl[entry.key],
      ),
  ];

  collections.sort((a, b) {
    final byTracks = b.trackCount.compareTo(a.trackCount);
    return byTracks != 0 ? byTracks : a.name.compareTo(b.name);
  });
  return collections;
}

String _nameOf(String sourceId, Map<String, SourceLabel> labels) {
  final label = labels[sourceId];
  if (label == null) return sourceId;
  if (label.localizedName.isNotEmpty) return label.localizedName;
  if (label.name.isNotEmpty) return label.name;
  return sourceId;
}
