import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/domain/audio_source_status.dart';

/// Where the audio of a track comes from.
///
/// The source is the answer of the resolver: the file the track is played
/// from, the state the badge shows and the copy that has to be fetched while
/// the track plays.
class PlaybackSource {
  /// The file the track is played from, `null` when it is streamed.
  final String? file;

  /// The state the badge shows for the track.
  final AudioSourceStatus status;

  /// The track whose copy has to be fetched in the background.
  ///
  /// The copy is fetched while the track plays, so the playback never waits
  /// for the transfer. It is `null` when the track is played from the disk
  /// and when no copy is needed at all.
  final Song? cacheTarget;

  const PlaybackSource({
    this.file,
    this.status = AudioSourceStatus.local,
    this.cacheTarget,
  });
}
