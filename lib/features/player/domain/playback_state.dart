import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/domain/audio_source_status.dart';
import 'package:tune/features/player/domain/play_mode.dart';

enum PlaybackStatus { idle, loading, playing, paused, error }

const Object _keep = Object();

/// Single source of truth for playback, including the queue.
class PlaybackState {
  final PlaybackStatus status;
  final Duration position;
  final Duration duration;
  final double volume;
  final double speed;
  final PlayMode playMode;

  /// The queue, in the order it plays.
  ///
  /// The list order is the play order: a shuffled queue is a queue that was
  /// rearranged once, so the user sees which track plays next.
  final List<Song> queue;

  /// The cursor: the identity of the track that plays, not its position.
  ///
  /// The position follows from the queue, so adding, removing or moving a
  /// track never leaves the cursor pointing at the wrong entry.
  final String? currentUri;

  /// The tracks that played before, most recent last.
  final List<String> history;
  final String? errorMessage;

  /// Where the audio of [currentSong] is read from.
  final AudioSourceStatus audioSourceStatus;

  /// Progress of the running cache transfer, between 0 and 1.
  final double downloadProgress;

  const PlaybackState({
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.speed = 1.0,
    this.playMode = PlayMode.sequential,
    this.queue = const [],
    this.currentUri,
    this.history = const [],
    this.errorMessage,
    this.audioSourceStatus = AudioSourceStatus.local,
    this.downloadProgress = 0,
  });

  static const PlaybackState initial = PlaybackState();

  /// The track that plays.
  Song? get currentSong {
    final index = currentIndex;
    return index < 0 ? null : queue[index];
  }

  /// The position of the playing track in the queue.
  ///
  /// It is -1 when the track is not part of the queue, which happens while the
  /// queue is replaced.
  int get currentIndex =>
      currentUri == null ? -1 : queue.indexWhere((song) => song.uri == currentUri);

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isLoading => status == PlaybackStatus.loading;
  bool get hasTrack => currentSong != null;
  bool get hasError => status == PlaybackStatus.error;
  bool get canGoNext => queue.length > 1;
  bool get canGoPrevious => queue.length > 1;

  /// Whether the local copy of the current track is being fetched.
  bool get isCaching => audioSourceStatus == AudioSourceStatus.caching;

  double get progress {
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  PlaybackState copyWith({
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    double? volume,
    double? speed,
    PlayMode? playMode,
    List<Song>? queue,
    Object? currentUri = _keep,
    List<String>? history,
    Object? errorMessage = _keep,
    AudioSourceStatus? audioSourceStatus,
    double? downloadProgress,
  }) {
    return PlaybackState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      playMode: playMode ?? this.playMode,
      queue: queue ?? this.queue,
      currentUri: identical(currentUri, _keep)
          ? this.currentUri
          : currentUri as String?,
      history: history ?? this.history,
      errorMessage: identical(errorMessage, _keep)
          ? this.errorMessage
          : errorMessage as String?,
      audioSourceStatus: audioSourceStatus ?? this.audioSourceStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}
