import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/domain/play_mode.dart';

/// The playback that survives a restart.
///
/// The status is deliberately not part of it: a start never restores
/// "playing". The shell opens paused at [position] so a launch does not make
/// a sound on its own.
class PlaybackSession {
  final List<Song> queue;
  final String currentUri;
  final Duration position;
  final PlayMode playMode;
  final List<String> history;

  const PlaybackSession({
    required this.queue,
    required this.currentUri,
    this.position = Duration.zero,
    this.playMode = PlayMode.sequential,
    this.history = const [],
  });

  /// The cursor always names a track that is still in the queue, so this
  /// lookup cannot fail for a session built by the store.
  Song get currentSong => queue.firstWhere((song) => song.uri == currentUri);
}
