import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/data/services/downloads/song_download_service.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/song_download_service_provider.dart';
import 'package:tune/data/services/providers/stream_url_resolver_provider.dart';
import 'package:tune/data/services/stream_url_resolver.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/audio_source_resolver.dart';
import 'package:tune/features/player/application/track_prefetcher.dart';
import 'package:tune/features/player/domain/audio_source_status.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_source.dart';
import 'package:tune/features/player/domain/playback_state.dart';
import 'package:tune/utils/logger.dart';

final playbackControllerProvider =
    StateNotifierProvider<PlaybackController, PlaybackState>((ref) {
      final audio = ref.watch(audioPlayerServiceProvider);
      final downloads = ref.watch(songDownloadServiceProvider);
      final resolver = ref.watch(streamUrlResolverProvider);
      return PlaybackController(audio, downloads, resolver);
    });

/// Owns playback and queue state.
///
/// This controller deliberately has no dependency on pages, app bars,
/// notifications, or library widgets. Side effects such as statistics or
/// history belong in listeners outside this class.
class PlaybackController extends StateNotifier<PlaybackState> {
  PlaybackController(this._audio, this._downloads, this._resolver)
    : _audioSources = AudioSourceResolver(_downloads),
      _prefetcher = TrackPrefetcher(_downloads),
      super(PlaybackState.initial) {
    _subscriptions.add(_audio.positionStream.listen(_handlePosition));
    _subscriptions.add(_audio.durationStream.listen(_handleDuration));
    _subscriptions.add(_audio.playingStream.listen(_handlePlaying));
    _subscriptions.add(
      _audio.completionStream.listen((_) {
        _handleCompletion();
      }),
    );
    _subscriptions.add(_audio.errorStream.listen(_handlePlayerError));
  }

  final AudioPlayerService _audio;
  final SongDownloadService _downloads;
  final StreamUrlResolver _resolver;
  final AudioSourceResolver _audioSources;
  final TrackPrefetcher _prefetcher;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Random _random = Random();

  /// How many times a failing track may get a fresh address.
  static const _maxRefreshAttempts = 1;

  String? _loadedSongUri;
  bool _handlingCompletion = false;
  int _loadRequest = 0;

  /// Number of refresh attempts spent on the current track.
  int _refreshAttempts = 0;

  /// Guards the asynchronous backend error handler while a refresh runs.
  bool _retryInProgress = false;

  /// Load request whose failure was already handled.
  ///
  /// A failing load can report the problem twice: once through the thrown
  /// exception and once through the backend error stream. Both must end up in
  /// the same handler, but only once.
  int? _failureHandledForRequest;

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

  /// Handles a failure the backend reported asynchronously.
  ///
  /// The backend may report a broken address long after the load future
  /// returned, so the track can sit in "loading" forever without this hook.
  /// A stream that breaks while the track plays is recovered the same way:
  /// the address is refreshed and the track continues where it stopped.
  Future<void> _handlePlayerError(AudioPlayerError error) async {
    if (!mounted || state.hasError || !state.hasTrack) return;
    if (_retryInProgress) return;

    final song = state.currentSong;
    if (song == null) return;

    if (state.status == PlaybackStatus.loading) {
      await _handleLoadFailure(
        index: state.currentIndex,
        song: song,
        request: _loadRequest,
        // The backend already reported the failure in the language of the
        // interface, so the message is shown as it is.
        message: error.message,
      );
      return;
    }

    if (state.status == PlaybackStatus.playing) {
      // The stream broke while the track played: the address is refreshed and
      // the track continues where it stopped.
      await _handleLoadFailure(
        index: state.currentIndex,
        song: song,
        request: _loadRequest,
        message: error.message,
        resumeAt: _audio.currentPosition,
      );
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
    final song = queue[index];
    state = state.copyWith(
      queue: queue,
      currentIndex: index,
      currentSong: song,
      status: PlaybackStatus.loading,
      position: Duration.zero,
      duration: _knownDuration(song),
      errorMessage: null,
      audioSourceStatus: _initialSourceStatus(song),
      downloadProgress: 0,
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
      _setError(AppStrings.instance.playbackPauseFailed('$error'), stackTrace);
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
      _setError(AppStrings.instance.playbackResumeFailed('$error'), stackTrace);
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
      _setError(AppStrings.instance.playbackSeekFailed('$error'), stackTrace);
    }
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0).toDouble();
    try {
      await _audio.setVolume(clamped);
      state = state.copyWith(volume: clamped);
    } catch (error, stackTrace) {
      _setError(AppStrings.instance.playbackVolumeFailed('$error'), stackTrace);
    }
  }

  Future<void> setSpeed(double speed) async {
    final clamped = speed.clamp(0.5, 2.0).toDouble();
    try {
      await _audio.setSpeed(clamped);
      state = state.copyWith(speed: clamped);
    } catch (error, stackTrace) {
      _setError(AppStrings.instance.playbackSpeedFailed('$error'), stackTrace);
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
    final removed = state.queue[index];
    final queue = List<Song>.of(state.queue)..removeAt(index);
    if (queue.isEmpty) {
      await clearQueue();
      return;
    }

    if (!removingCurrent) {
      // The prefetch of a track that left the queue is not needed anymore.
      _prefetcher.stopIf(removed);
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
    _prefetcher.stop();
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
      audioSourceStatus: AudioSourceStatus.local,
      downloadProgress: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Loads the track at [index] and starts playing it.
  ///
  /// [isRetry] marks the attempt that follows a successful address refresh;
  /// only that attempt keeps the refresh budget, every fresh selection starts
  /// over with a full budget.
  ///
  /// [startPosition] is where the playback continues, which matters when a
  /// broken stream is replaced by a fresh address.
  Future<void> _startAt(
    int index, {
    bool isRetry = false,
    Duration startPosition = Duration.zero,
  }) async {
    if (index < 0 || index >= state.queue.length) return;
    final song = state.queue[index];
    final request = ++_loadRequest;
    if (!isRetry) _refreshAttempts = 0;
    _prefetcher.release(
      keep: song,
      index: index,
      queue: state.queue,
      playMode: state.playMode,
    );

    state = state.copyWith(
      currentIndex: index,
      currentSong: song,
      status: PlaybackStatus.loading,
      position: startPosition,
      duration: _knownDuration(song),
      errorMessage: null,
      audioSourceStatus: _initialSourceStatus(song),
      downloadProgress: 0,
    );

    try {
      final source = await _resolveSource(song, request);
      if (!mounted || request != _loadRequest) return;

      await _playSong(song, source, request, startPosition);
      if (!mounted || request != _loadRequest) return;
    } catch (error, stackTrace) {
      if (!mounted || request != _loadRequest) return;
      await _handleLoadFailure(
        index: index,
        song: song,
        request: request,
        message: AppStrings.instance.playbackFailed('$error'),
        stackTrace: stackTrace,
      );
    }
  }

  /// Answers where the audio of [song] comes from and starts its cache.
  Future<PlaybackSource> _resolveSource(Song song, int request) async {
    final source = await _audioSources.sourceFor(song);
    if (!mounted || request != _loadRequest) return source;
    state = state.copyWith(audioSourceStatus: source.status);

    final cacheTarget = source.cacheTarget;
    if (cacheTarget != null) {
      unawaited(_cacheInBackground(cacheTarget, request));
    }
    return source;
  }

  /// Plays the track and reports where the playback stands.
  Future<void> _playSong(
    Song song,
    PlaybackSource source,
    int request,
    Duration startPosition,
  ) async {
    await _audio.play(song, localFilePath: source.file);
    if (!mounted || request != _loadRequest) return;
    _loadedSongUri = song.uri;

    unawaited(
      _prefetcher.prefetch(
        index: state.currentIndex,
        queue: state.queue,
        playMode: state.playMode,
      ),
    );

    if (startPosition > Duration.zero) {
      await _restorePosition(startPosition);
      if (!mounted || request != _loadRequest) return;
    }

    final duration = _audio.duration;
    state = state.copyWith(
      status: _audio.isPlaying
          ? PlaybackStatus.playing
          : PlaybackStatus.paused,
      position: _audio.currentPosition,
      duration: duration.inMilliseconds > 0 ? duration : _knownDuration(song),
    );
  }

  /// Moves the playback back to the position it reached before a stream broke.
  Future<void> _restorePosition(Duration position) async {
    try {
      await _audio.seekTo(position);
    } catch (error, stackTrace) {
      Log.error('恢复播放位置失败: $error\n$stackTrace');
    }
  }

  /// Single entry point for every playback failure.
  ///
  /// A remote track whose address expired gets one fresh address and one
  /// retry; everything else fails right away so the user sees the error.
  /// [resumeAt] is where the playback continues, which matters when a stream
  /// that broke while playing is replaced by a fresh address.
  Future<void> _handleLoadFailure({
    required int index,
    required Song song,
    required int request,
    required String message,
    Duration resumeAt = Duration.zero,
    StackTrace? stackTrace,
  }) async {
    if (!mounted || request != _loadRequest) return;
    if (_failureHandledForRequest == request) return;
    _failureHandledForRequest = request;
    _loadedSongUri = null;

    final refreshed = await _tryRefresh(song, request);
    if (!mounted || request != _loadRequest) return;

    if (refreshed != null) {
      _replaceQueueEntry(index, refreshed);
      await _startAt(index, isRetry: true, startPosition: resumeAt);
      return;
    }

    if (song.isRemote) {
      state = state.copyWith(audioSourceStatus: AudioSourceStatus.failed);
    }
    _setError(message, stackTrace);
  }

  /// Asks the owning source for a new address of [song].
  ///
  /// Returns `null` when the track has no source, when the source cannot
  /// issue a new address, or when the refresh budget is used up.
  Future<Song?> _tryRefresh(Song song, int request) async {
    if (_refreshAttempts >= _maxRefreshAttempts) return null;
    if (!song.isRemote) return null;
    final sourceId = song.sourceId;
    if (sourceId == null || sourceId.isEmpty) return null;

    _refreshAttempts++;
    _retryInProgress = true;
    try {
      final refreshed = await _resolver.refresh(song);
      if (!mounted || request != _loadRequest) return null;
      if (refreshed == null) return null;
      Log.info('已刷新播放地址: ${song.title}');
      return refreshed;
    } catch (error, stackTrace) {
      Log.error('刷新播放地址失败: $error\n$stackTrace');
      return null;
    } finally {
      _retryInProgress = false;
    }
  }

  /// Replaces the queued track with the refreshed one.
  ///
  /// The new address stays inside the queue; the library keeps the address
  /// that was stored during the last scan.
  void _replaceQueueEntry(int index, Song song) {
    if (index < 0 || index >= state.queue.length) return;
    final queue = List<Song>.of(state.queue)..[index] = song;
    state = state.copyWith(queue: List<Song>.unmodifiable(queue));
  }

  /// Fetches the local copy of [song] while the track plays.
  ///
  /// The transfer never decides the playback: when it fails, the track keeps
  /// playing from the network and only the offline copy is missing.
  Future<void> _cacheInBackground(Song song, int request) async {
    try {
      await _downloads.download(
        song,
        onProgress: (progress) {
          if (!mounted || request != _loadRequest) return;
          state = state.copyWith(downloadProgress: progress);
        },
      );
    } catch (error, stackTrace) {
      Log.error('缓存音源失败: $error\n$stackTrace');
      if (!mounted || request != _loadRequest) return;
      state = state.copyWith(
        audioSourceStatus: AudioSourceStatus.streaming,
        downloadProgress: 0,
      );
      return;
    }

    if (!mounted || request != _loadRequest) return;
    state = state.copyWith(
      audioSourceStatus: AudioSourceStatus.cached,
      downloadProgress: 1,
    );
  }

  /// The source status a track starts in before it is resolved.
  AudioSourceStatus _initialSourceStatus(Song song) {
    return song.isRemote ? AudioSourceStatus.streaming : AudioSourceStatus.local;
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
