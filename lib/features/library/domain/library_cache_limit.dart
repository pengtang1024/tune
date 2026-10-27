import 'package:tune/domain/models/song.dart';

/// Keeps the newest tracks of every remote source when a limit is set.
///
/// The local music is never trimmed: those files are on the disk, and the
/// limit is about the windows a service keeps answering with. A limit of
/// zero keeps everything.
List<Song> applyCacheLimit(List<Song> songs, int limit) {
  if (limit <= 0) return songs;

  final remoteBySource = <String, List<Song>>{};
  final local = <Song>[];
  for (final song in songs) {
    final sourceId = song.sourceId ?? 'local';
    if (sourceId == 'local') {
      local.add(song);
      continue;
    }
    (remoteBySource[sourceId] ??= []).add(song);
  }

  final kept = <Song>[...local];
  for (final tracks in remoteBySource.values) {
    tracks.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    kept.addAll(tracks.take(limit));
  }
  return kept;
}
