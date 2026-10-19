import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_state.dart';
import 'package:tune/utils/logger.dart';

final playbackControllerProvider =
    StateNotifierProvider<PlaybackController, PlaybackState>((ref) {
      final audio = ref.watch(audioPlayerServiceProvider);
      return PlaybackController(audio);
    });

/// Owns playback and queue state.
///
/// This controller deliberately has no dependency on pages, app bars,
/// notifications, or library widgets. Side effects such as statistics or
/// history belong in listeners outside this class.
class PlaybackController extends StateNotifier<PlaybackState> {
  PlaybackController(this._audio) : super(PlaybackState.initial) {
    _subscriptions.add(_audio.positionStream.listen(_handlePosition));
    _subscriptions.add(_audio.durationStream.listen(_handleDuration));
    _subscriptions.add(_audio.playingStream.listen(_handlePlaying));
    _subscriptions.add(
      _audio.completionStream.listen((_) {
        _handleCompletion();
      }),
    );
  }

  final AudioPlayerService _audio;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Random _random = Random();

  String? _loadedSongUri;
  bool _handlingCompletion = false;
  int _loadRequest = 0;

  // ---------------------------------------------------------------------------
  // Audio event handlers
  // ---------------------------------------------------------------------------

  void _handlePosition(Duration position) {
    if (!mounted || !state.hasTrack || state.hasError) return;
    if (position == state.position) return;

    state = state.copyWith(
      position: position,
      status: state.status == PlaybackStatus.loading && _audio.isPlaying
          ? PlaybackStatus.playing
          : state.status,
      duration: _audio.duration.inMilliseconds > 0
          ? _audio.duration
          : state.duration,
    );
  }

  void _handleDuration(Duration? duration) {
    if (!mounted || duration == null || duration == state.duration) return;
    state = state.copyWith(duration: duration);
  }

  void _handlePlaying(bool isPlaying) {
    if (!mounted || !state.hasTrack || state.hasError) return;
    if (state.status == PlaybackStatus.loading) {
      if (isPlaying) {
        state = state.copyWith(status: PlaybackStatus.playing);
      }
      return;
    }
    state = state.copyWith(
      status: isPlaying ? PlaybackStatus.playing : PlaybackStatus.paused,
    );
  }

  Future<void> _handleCompletion() async {
    if (!mounted || _handlingCompletion || !state.hasTrack || state.hasError) {
      return;
    }

    _handlingCompletion = true;
    try {
      if (state.playMode == PlayMode.repeatOne) {
        await _startAt(state.currentIndex);
      } else {
        await next();
      }
    } finally {
      _handlingCompletion = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Public playback API
  // ---------------------------------------------------------------------------

  Future<void> playQueue(List<Song> songs, {int startIndex = 0}) async {
    final playable = <Song>[];
    var index = 0;
    var foundStart = false;
    for (var i = 0; i < songs.length; i++) {
      final song = songs[i];
      if (song.uri.isEmpty) continue;
      if (!foundStart && i >= startIndex) {
        index = playable.length;
        foundStart = true;
      }
      playable.add(song);
    }
    if (playable.isEmpty) return;

    final queue = List<Song>.unmodifiable(playable);
    if (!foundStart) index = queue.length - 1;
    index = index.clamp(0, queue.length - 1);
    state = state.copyWith(
      queue: queue,
      currentIndex: index,
      currentSong: queue[index],
      status: PlaybackStatus.loading,
      position: Duration.zero,
      duration: _knownDuration(queue[index]),
      errorMessage: null,
    );

    await _startAt(index);
  }

  Future<void> playSong(Song song) => playQueue([song]);

  Future<void> playAt(int index) => _startAt(index);

  Future<void> togglePlayPause() async {
    if (!state.hasTrack || state.isLoading) return;
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> pause() async {
    if (!state.hasTrack) return;
    try {
      await _audio.pause();
      state = state.copyWith(status: PlaybackStatus.paused);
    } catch (error, stackTrace) {
      _setError('暂停失败: $error', stackTrace);
    }
  }

  Future<void> resume() async {
    if (!state.hasTrack) return;

    // A queued track may not have been loaded into the audio backend yet.
    if (_loadedSongUri != state.currentSong!.uri) {
      await _startAt(state.currentIndex);
      return;
    }

    try {
      await _audio.resume();
      state = state.copyWith(status: PlaybackStatus.playing);
    } catch (error, stackTrace) {
      _setError('继续播放失败: $error', stackTrace);
    }
  }

  Future<void> next() async {
    if (state.queue.isEmpty) return;

    final index = state.playMode == PlayMode.shuffle
        ? _randomIndex(excluding: state.currentIndex)
        : (state.currentIndex + 1) % state.queue.length;
    await _startAt(index);
  }

  Future<void> previous() async {
    if (state.queue.isEmpty) return;

    final index = state.playMode == PlayMode.shuffle
        ? _randomIndex(excluding: state.currentIndex)
        : (state.currentIndex - 1 + state.queue.length) % state.queue.length;
    await _startAt(index);
  }

  Future<void> seekTo(Duration position) async {
    if (!state.hasTrack) return;

    final clamped = Duration(
      milliseconds: position.inMilliseconds.clamp(
        0,
        state.duration.inMilliseconds > 0
            ? state.duration.inMilliseconds
            : position.inMilliseconds,
      ),
    );

    try {
      await _audio.seekTo(clamped);
      state = state.copyWith(position: clamped);
    } catch (error, stackTrace) {
      _setError('跳转失败: $error', stackTrace);
    }
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0).toDouble();
    try {
      await _audio.setVolume(clamped);
      state = state.copyWith(volume: clamped);
    } catch (error, stackTrace) {
      _setError('设置音量失败: $error', stackTrace);
    }
  }

  Future<void> setSpeed(double speed) async {
    final clamped = speed.clamp(0.5, 2.0).toDouble();
    try {
      await _audio.setSpeed(clamped);
      state = state.copyWith(speed: clamped);
    } catch (error, stackTrace) {
      _setError('设置速度失败: $error', stackTrace);
    }
  }

  void cyclePlayMode() {
    final nextMode =
        PlayMode.values[(state.playMode.index + 1) % PlayMode.values.length];
    state = state.copyWith(playMode: nextMode);
  }

  // ---------------------------------------------------------------------------
  // Queue API
  // ---------------------------------------------------------------------------

  void addToQueue(Song song) {
    if (song.uri.isEmpty) return;
    if (state.queue.any((item) => item.uri == song.uri)) return;

    final queue = List<Song>.unmodifiable([...state.queue, song]);
    if (!state.hasTrack) {
      state = state.copyWith(
        queue: queue,
        currentIndex: 0,
        currentSong: queue.first,
        status: PlaybackStatus.paused,
        duration: _knownDuration(queue.first),
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(queue: queue);
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= state.queue.length) return;

    final wasPlaying = state.isPlaying;
    final removingCurrent = index == state.currentIndex;
    final queue = List<Song>.of(state.queue)..removeAt(index);
    if (queue.isEmpty) {
      await clearQueue();
      return;
    }

    if (!removingCurrent) {
      state = state.copyWith(
        queue: List<Song>.unmodifiable(queue),
        currentIndex: index < state.currentIndex
            ? state.currentIndex - 1
            : state.currentIndex,
      );
      return;
    }

    final nextIndex = index >= queue.length ? queue.length - 1 : index;
    final nextSong = queue[nextIndex];
    state = state.copyWith(
      queue: List<Song>.unmodifiable(queue),
      currentIndex: nextIndex,
      currentSong: nextSong,
      status: PlaybackStatus.paused,
      position: Duration.zero,
      duration: _knownDuration(nextSong),
      errorMessage: null,
    );
    _loadedSongUri = null;

    if (wasPlaying) {
      await _startAt(nextIndex);
    }
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.queue.length) return;

    var targetIndex = newIndex;
    if (targetIndex > oldIndex) targetIndex -= 1;
    if (targetIndex < 0) targetIndex = 0;
    if (targetIndex >= state.queue.length) {
      targetIndex = state.queue.length - 1;
    }
    if (targetIndex == oldIndex) return;

    final currentUri = state.currentSong?.uri;
    final queue = List<Song>.of(state.queue);
    final moved = queue.removeAt(oldIndex);
    queue.insert(targetIndex, moved);

    final newCurrentIndex = currentUri == null
        ? state.currentIndex
        : queue.indexWhere((song) => song.uri == currentUri);

    state = state.copyWith(
      queue: List<Song>.unmodifiable(queue),
      currentIndex: newCurrentIndex >= 0 ? newCurrentIndex : state.currentIndex,
    );
  }

  Future<void> clearQueue() async {
    _loadRequest++;
    try {
      await _audio.stop();
    } catch (error, stackTrace) {
      Log.error('停止播放失败: $error\n$stackTrace');
    }

    _loadedSongUri = null;
    state = state.copyWith(
      currentSong: null,
      status: PlaybackStatus.idle,
      position: Duration.zero,
      duration: Duration.zero,
      queue: const [],
      currentIndex: -1,
      errorMessage: null,
    );
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _startAt(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    final song = state.queue[index];
    final request = ++_loadRequest;

    state = state.copyWith(
      currentIndex: index,
      currentSong: song,
      status: PlaybackStatus.loading,
      position: Duration.zero,
      duration: _knownDuration(song),
      errorMessage: null,
    );

    try {
      await _audio.play(song);
      if (!mounted || request != _loadRequest) return;
      _loadedSongUri = song.uri;

      final duration = _audio.duration;
      state = state.copyWith(
        status: _audio.isPlaying
            ? PlaybackStatus.playing
            : PlaybackStatus.paused,
        position: _audio.currentPosition,
        duration: duration.inMilliseconds > 0 ? duration : _knownDuration(song),
      );
    } catch (error, stackTrace) {
      if (!mounted || request != _loadRequest) return;
      _loadedSongUri = null;
      _setError('播放失败: $error', stackTrace);
    }
  }

  int _randomIndex({required int excluding}) {
    if (state.queue.length <= 1) return state.currentIndex;
    var index = _random.nextInt(state.queue.length);
    while (index == excluding) {
      index = _random.nextInt(state.queue.length);
    }
    return index;
  }

  Duration _knownDuration(Song song) {
    return song.durationInMillis > 0
        ? Duration(milliseconds: song.durationInMillis)
        : Duration.zero;
  }

  void _setError(String message, [StackTrace? stackTrace]) {
    Log.error(message, stackTrace);
    state = state.copyWith(status: PlaybackStatus.error, errorMessage: message);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
