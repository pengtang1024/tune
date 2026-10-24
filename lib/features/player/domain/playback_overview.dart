import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/domain/audio_source_status.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_state.dart';

/// The slow half of the playback.
///
/// The state of the player holds two kinds of values: the queue, the mode and
/// the volume change every few seconds, the position changes several times a
/// second. A surface that watches the whole state is rebuilt by the position
/// even when it only draws the title of the track.
///
/// This is the part that changes slowly. The position is not in it, and the
/// surfaces that show the position ask for it on their own.
class PlaybackOverview {
  final PlaybackStatus status;

  /// The track that plays.
  final Song? currentSong;

  /// Where the track sits in the queue, or -1 when the queue holds nothing
  /// that points at it.
  final int currentIndex;

  final List<Song> queue;
  final PlayMode playMode;
  final double volume;
  final String? errorMessage;

  /// Where the audio of the current track is read from.
  final AudioSourceStatus audioSourceStatus;

  const PlaybackOverview({
    this.status = PlaybackStatus.idle,
    this.currentSong,
    this.currentIndex = -1,
    this.queue = const [],
    this.playMode = PlayMode.sequential,
    this.volume = 1,
    this.errorMessage,
    this.audioSourceStatus = AudioSourceStatus.local,
  });

  bool get hasTrack => currentSong != null;
  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isLoading => status == PlaybackStatus.loading;
  bool get hasError => status == PlaybackStatus.error;
  bool get canGoNext => queue.length > 1;
  bool get canGoPrevious => queue.length > 1;

  /// Where the track sits in the queue, counted from one.
  ///
  /// It is zero when the queue holds nothing to point at.
  int get queuePosition {
    if (!hasTrack || queue.length < 2) return 0;
    final position = currentIndex + 1;
    return position > 0 && position <= queue.length ? position : 0;
  }
}
