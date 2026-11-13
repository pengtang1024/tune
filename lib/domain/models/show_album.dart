import 'package:tune/core/utils/text_order.dart';
import 'package:tune/domain/models/album_summary.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';

/// One show of the library: the episodes of a podcast or the chapters of a
/// book, already merged across the sources that publish it.
class ShowAlbum {
  /// Stable identity of the show inside the library.
  ///
  /// A show published by one source keeps the key of that source; a show the
  /// library merged from several sources carries the sources it joined, so
  /// two same-named shows that never overlap stay two cards.
  final String key;

  final String name;
  final String artist;
  final ContentKind kind;

  /// The episodes, one per episode, in the order of the show.
  final List<Song> songs;

  const ShowAlbum({
    required this.key,
    required this.name,
    required this.artist,
    required this.kind,
    required this.songs,
  });
}

/// The name a show is compared by: two feeds that carry the same show write
/// the same name, so case and padding carry no meaning.
String normalizedShowNameOf(String album) => album.trim().toLowerCase();

/// The title an episode is compared by.
String normalizedEpisodeTitleOf(String title) =>
    title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// The key of a show merged from several sources.
String mergedShowKeyOf(String album, Iterable<String> sourceIds) {
  final ids = [for (final id in sourceIds) id.isEmpty ? 'local' : id]..sort();
  return '${normalizedShowNameOf(album)}\u0000show\u0000${ids.join('\u0001')}';
}

/// Whether [key] belongs to a show merged from several sources.
bool isMergedShowKey(String key) {
  final parts = key.split('\u0000');
  return parts.length >= 3 && parts[1] == 'show';
}

/// Which copy of an episode is played when the same episode comes from more
/// than one source: a file on this machine first, then the feed the reader
/// added, then a catalogue, then the archive.
int playbackPriorityOf(String? sourceId) {
  if (sourceId == null || sourceId.isEmpty || sourceId == 'local') return 0;
  final type = sourceTypeOfId(sourceId);
  if (type == 'podcast_rss' || type == 'librivox' || type == 'audiobookshelf') {
    return 1;
  }
  if (type == 'podcast_catalog' || type == 'podcast_apple') return 2;
  if (type == 'internet_archive') return 3;
  return 2;
}

/// Whether two tracks are the same episode: the same title and, when both
/// carry a length, a length within two seconds. A missing length cannot
/// disprove a duplicate, so the title alone decides there.
bool sameEpisode({required Song left, required Song right}) {
  final title = normalizedEpisodeTitleOf(left.title);
  if (title.isEmpty || title != normalizedEpisodeTitleOf(right.title)) {
    return false;
  }
  if (left.durationInMillis <= 0 || right.durationInMillis <= 0) return true;
  return (left.durationInMillis - right.durationInMillis).abs() <=
      _episodeTolerance;
}

const int _episodeTolerance = 2000;

/// The episodes of [songs], one per episode, keeping the copy that plays
/// first by [playbackPriorityOf].
List<Song> dedupedEpisodesOf(Iterable<Song> songs) {
  final ordered = songs.toList()
    ..sort((left, right) {
      final byPriority = playbackPriorityOf(
        left.sourceId,
      ).compareTo(playbackPriorityOf(right.sourceId));
      if (byPriority != 0) return byPriority;
      final byTitle = compareText(left.title, right.title);
      if (byTitle != 0) return byTitle;
      return left.uri.compareTo(right.uri);
    });
  final kept = <Song>[];
  for (final song in ordered) {
    if (!kept.any((other) => sameEpisode(left: other, right: song))) {
      kept.add(song);
    }
  }
  return kept;
}

/// The order the episodes of a show read in.
int albumOrderOf(Song left, Song right) {
  final disc = (left.discNumber ?? 1).compareTo(right.discNumber ?? 1);
  if (disc != 0) return disc;
  final track = (left.trackNumber ?? 0).compareTo(right.trackNumber ?? 0);
  if (track != 0) return track;
  return compareText(left.title, right.title);
}

/// Groups spoken tracks into shows, merging the sources of one show.
///
/// Two sources are merged only when the show names are equal after
/// [normalizedShowNameOf] and at least two episodes prove it: two episode
/// titles or two lengths within [sameEpisode]'s tolerance. A name alone is
/// not evidence, because two different shows can share one.
List<ShowAlbum> spokenAlbumsOf(List<Song> songs) {
  final groups = <String, List<Song>>{};
  for (final song in songs) {
    final kind = contentKindOf(song);
    if (!kind.isSpokenWord) continue;
    final name = normalizedShowNameOf(song.album);
    if (name.isEmpty) continue;
    groups.putIfAbsent('$name\u0000${kind.name}', () => []).add(song);
  }
  return [
    for (final group in groups.values) ..._clustersOf(group),
  ];
}

List<ShowAlbum> _clustersOf(List<Song> songs) {
  final bySource = <String, List<Song>>{};
  for (final song in songs) {
    bySource.putIfAbsent(song.sourceId ?? 'local', () => []).add(song);
  }
  final sources = bySource.keys.toList()..sort();
  final parents = {for (final source in sources) source: source};

  String rootOf(String source) {
    var root = source;
    while (parents[root] != root) {
      root = parents[root]!;
    }
    var walk = source;
    while (parents[walk] != root) {
      final next = parents[walk]!;
      parents[walk] = root;
      walk = next;
    }
    return root;
  }

  for (var left = 0; left < sources.length; left++) {
    for (var right = left + 1; right < sources.length; right++) {
      if (!_showsOverlap(
        bySource[sources[left]]!,
        bySource[sources[right]]!,
      )) {
        continue;
      }
      final leftRoot = rootOf(sources[left]);
      final rightRoot = rootOf(sources[right]);
      if (leftRoot != rightRoot) parents[rightRoot] = leftRoot;
    }
  }

  final clusters = <String, List<String>>{};
  for (final source in sources) {
    clusters.putIfAbsent(rootOf(source), () => []).add(source);
  }
  return [
    for (final cluster in clusters.values) _albumOfCluster(cluster, bySource),
  ];
}

/// Whether two sources of one show carry at least two episodes in common.
bool _showsOverlap(List<Song> left, List<Song> right) {
  final leftTitles = {
    for (final song in left) normalizedEpisodeTitleOf(song.title),
  }..remove('');
  final rightTitles = {
    for (final song in right) normalizedEpisodeTitleOf(song.title),
  }..remove('');
  var matches = 0;
  for (final title in leftTitles) {
    if (!rightTitles.contains(title)) continue;
    matches++;
    if (matches >= 2) return true;
  }

  final leftDurations = [
    for (final song in left)
      if (song.durationInMillis > 0) song.durationInMillis,
  ];
  final rightDurations = [
    for (final song in right)
      if (song.durationInMillis > 0) song.durationInMillis,
  ];
  matches = 0;
  for (final duration in leftDurations) {
    if (!rightDurations.any((other) => (other - duration).abs() <= _episodeTolerance)) {
      continue;
    }
    matches++;
    if (matches >= 2) return true;
  }
  return false;
}

ShowAlbum _albumOfCluster(
  List<String> sources,
  Map<String, List<Song>> bySource,
) {
  final kept = dedupedEpisodesOf([
    for (final source in sources) ...bySource[source]!,
  ]);
  final ordered = List<Song>.of(kept)..sort(albumOrderOf);
  final first = ordered.first;
  final name = first.album.trim();
  final key = sources.length == 1
      ? albumKeyOf(album: name, artist: first.artist, sourceId: first.sourceId)
      : mergedShowKeyOf(name, sources);
  return ShowAlbum(
    key: key,
    name: name,
    artist: first.artist.trim(),
    kind: contentKindOf(first),
    songs: List.unmodifiable(ordered),
  );
}
