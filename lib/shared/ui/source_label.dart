import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';

/// Label of the source a track came from.
///
/// Local files have no source, so they get no label; remote tracks are named
/// after the source that provided them.
SourceLabel? sourceLabel(Song song, Map<String, SourceLabel> sourceLabels) {
  final sourceId = song.sourceId;
  if (sourceId == null || sourceId.isEmpty || sourceId == 'local') return null;
  return sourceLabels[sourceId];
}
