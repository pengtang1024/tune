import 'package:audio_service/audio_service.dart' as audio;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/playback_state.dart';

/// The bridge between the system media session and [PlaybackController].
///
/// The controller stays the only owner of the queue and of the playback
/// state. This handler mirrors the state into the notification and the lock
/// screen, and hands their actions back to the controller; it never keeps a
/// second queue of its own.
class TuneAudioHandler extends audio.BaseAudioHandler {
  ProviderContainer? _container;
  ProviderSubscription<PlaybackState>? _subscription;

  /// The queue that was sent to the system last.
  ///
  /// The controller keeps the same list while the position moves, so the
  /// reference tells whether the queue really changed.
  List<Song>? _mirroredQueue;

  /// The track the system was told about last.
  String? _publishedUri;

  /// Starts the background service and returns its handler.
  ///
  /// This has to run before the first frame: the service creates the
  /// notification channel and the media session while the engine is still
  /// starting, and a notification cannot be shown without them.
  static Future<TuneAudioHandler> start() {
    return audio.AudioService.init<TuneAudioHandler>(
      builder: TuneAudioHandler.new,
      config: const audio.AudioServiceConfig(
        androidNotificationChannelId: 'cn.iouf.tune.playback',
        androidNotificationChannelName: 'Tune',
        androidNotificationChannelDescription: 'Playback controls of Tune',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  }

  /// Connects the handler to the playback state of [container].
  ///
  /// The container is attached after the first frame: the controller reads
  /// the saved session and the preferences, which are warming up while the
  /// engine starts.
  void attach(ProviderContainer container) {
    if (_subscription != null) return;
    _container = container;
    _subscription = container.listen<PlaybackState>(
      playbackControllerProvider,
      (_, next) => _publish(next),
      fireImmediately: true,
    );
  }

  PlaybackController? get _controller =>
      _container?.read(playbackControllerProvider.notifier);

  void _publish(PlaybackState state) {
    final song = state.currentSong;
    if (song?.uri != _publishedUri) {
      _publishedUri = song?.uri;
      mediaItem.add(song == null ? null : _itemOf(song));
    }
    if (!identical(state.queue, _mirroredQueue)) {
      _mirroredQueue = state.queue;
      queue.add([for (final item in state.queue) _itemOf(item)]);
    }
    playbackState.add(_stateOf(state));
  }

  audio.PlaybackState _stateOf(PlaybackState state) {
    return audio.PlaybackState(
      controls: [
        audio.MediaControl.skipToPrevious,
        state.isPlaying ? audio.MediaControl.pause : audio.MediaControl.play,
        audio.MediaControl.skipToNext,
      ],
      systemActions: const {audio.MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: switch (state.status) {
        PlaybackStatus.idle => audio.AudioProcessingState.idle,
        PlaybackStatus.loading => audio.AudioProcessingState.loading,
        PlaybackStatus.playing ||
        PlaybackStatus.paused => audio.AudioProcessingState.ready,
        PlaybackStatus.error => audio.AudioProcessingState.error,
      },
      playing: state.isPlaying,
      updatePosition: state.position,
      bufferedPosition: state.position,
      speed: state.speed,
      queueIndex: state.currentIndex < 0 ? null : state.currentIndex,
      errorMessage: state.errorMessage,
    );
  }

  audio.MediaItem _itemOf(Song song) {
    return audio.MediaItem(
      id: song.uri,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: Duration(milliseconds: song.duration),
      artUri: _artOf(song),
    );
  }

  Uri? _artOf(Song song) {
    final local = song.albumArtPath;
    if (local != null && local.isNotEmpty) return Uri.file(local);
    final remote = song.artworkUrl;
    if (remote != null && remote.isNotEmpty) return Uri.tryParse(remote);
    return null;
  }

  @override
  Future<void> play() async {
    await _controller?.resume();
  }

  @override
  Future<void> pause() async {
    await _controller?.pause();
  }

  @override
  Future<void> stop() async {
    await _controller?.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _controller?.seekTo(position);
  }

  @override
  Future<void> skipToNext() async {
    await _controller?.next();
  }

  @override
  Future<void> skipToPrevious() async {
    await _controller?.previous();
  }
}
