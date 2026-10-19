import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/domain/audio_source_status.dart';
import 'package:tune/features/player/domain/play_mode.dart';

enum PlaybackStatus { idle, loading, playing, paused, error }

const Object _keep = Object();

/// Single source of truth for playback, including the queue.
class PlaybackState {
  final Song? currentSong;
  final PlaybackStatus status;
  final Duration position;
  final Duration duration;
  final double volume;
  final double speed;
  final PlayMode playMode;
  final List<Song> queue;
  final int currentIndex;
  final String? errorMessage;

  /// Where the audio of [currentSong] is read from.
  final AudioSourceStatus audioSourceStatus;

  /// Progress of the running download, between 0 and 1.
  final double downloadProgress;

  const PlaybackState({
    this.currentSong,
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.speed = 1.0,
    this.playMode = PlayMode.sequential,
    this.queue = const [],
    this.currentIndex = -1,
    this.errorMessage,
    this.audioSourceStatus = AudioSourceStatus.local,
    this.downloadProgress = 0,
  });

  static const PlaybackState initial = PlaybackState();

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isLoading => status == PlaybackStatus.loading;
  bool get hasTrack => currentSong != null;
  bool get hasError => status == PlaybackStatus.error;
  bool get canGoNext => queue.length > 1;
  bool get canGoPrevious => queue.length > 1;

  bool get isDownloading => audioSourceStatus == AudioSourceStatus.downloading;

  double get progress {
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  PlaybackState copyWith({
    Object? currentSong = _keep,
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    double? volume,
    double? speed,
    PlayMode? playMode,
    List<Song>? queue,
    int? currentIndex,
    Object? errorMessage = _keep,
    AudioSourceStatus? audioSourceStatus,
    double? downloadProgress,
  }) {
    return PlaybackState(
      currentSong: identical(currentSong, _keep)
          ? this.currentSong
          : currentSong as Song?,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      playMode: playMode ?? this.playMode,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      errorMessage: identical(errorMessage, _keep)
          ? this.errorMessage
          : errorMessage as String?,
      audioSourceStatus: audioSourceStatus ?? this.audioSourceStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}
