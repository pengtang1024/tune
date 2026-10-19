import 'package:tune/data/services/stream_url_resolver.dart';
import 'package:tune/domain/models/song.dart';

/// In-memory stand-in for the source side of the refresh contract.
///
/// Tests declare the answer per track uri through [responses]; tracks without
/// an entry cannot be refreshed.
class FakeStreamUrlResolver implements StreamUrlResolver {
  /// Maps a track uri to the copy that carries a fresh address.
  final Map<String, Song> responses = {};

  /// Uris of the tracks whose address was requested.
  final List<String> refreshedUris = [];

  /// When true every refresh throws instead of answering.
  bool failRefresh = false;

  @override
  Future<Song?> refresh(Song song) async {
    refreshedUris.add(song.uri);
    if (failRefresh) throw StateError('refresh failed');
    return responses[song.uri];
  }
}
