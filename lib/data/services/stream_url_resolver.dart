import 'package:tune/domain/models/song.dart';

/// Rebuilds the playable address of a track whose remote link expired.
///
/// The player depends on this contract only, so playback stays independent
/// from the music source feature that knows how to issue fresh addresses.
abstract class StreamUrlResolver {
  /// Returns a copy of [song] that carries a fresh address.
  ///
  /// Returns `null` when the source behind [song] cannot issue one.
  Future<Song?> refresh(Song song);
}
