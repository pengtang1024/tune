import 'package:tune/domain/models/song.dart';

/// A service that can look up the lyrics of a track.
///
/// A source answers the question with the lyrics it owns. A provider is the
/// fallback for the sources that do not publish lyrics at all, so a track from
/// an open catalogue can still be read along with its words.
abstract class LyricsProvider {
  /// Returns the lyric sheet of [song], or `null` when nothing was found.
  ///
  /// The sheet may carry time stamps; the player understands both formats.
  Future<String?> lookup(Song song);
}
