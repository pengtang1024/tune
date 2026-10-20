import 'package:tune/domain/models/song.dart';

/// Remembers which track is playing.
///
/// The system controls name a track by a number that has to change when the
/// track changes, so the tracker keeps the address of the last song and counts
/// the songs that came after it.
class PlaybackTrackTracker {
  String? _uri;
  int _number = 0;

  /// The number of the track that plays.
  ///
  /// The number grows every time a new track starts, so the system controls
  /// can tell one track from another.
  int get number => _number;

  /// Remembers the song and tells whether it is a different one.
  bool remember(Song song) {
    if (song.uri == _uri) return false;
    _uri = song.uri;
    _number++;
    return true;
  }
}
