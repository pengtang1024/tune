import 'package:tune/domain/models/song.dart';

/// Name of the source a track came from.
///
/// Local files have no source, so they get no label; remote tracks are named
/// after the source that provided them.
String? sourceLabel(Song song, Map<String, String> sourceNames) {
  final sourceId = song.sourceId;
  if (sourceId == null || sourceId.isEmpty || sourceId == 'local') return null;
  return sourceNames[sourceId] ?? sourceId;
}
