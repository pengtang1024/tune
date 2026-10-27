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
import 'package:tune/features/library/application/dead_songs_controller.dart';
import 'package:tune/features/player/application/audio_source_resolver.dart';
import 'package:tune/features/player/application/playback_session_recorder.dart';
import 'package:tune/features/player/data/playback_session_store.dart';
import 'package:tune/features/player/application/track_prefetcher.dart';
import 'package:tune/features/player/domain/audio_source_status.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_source.dart';
import 'package:tune/features/player/domain/playback_state.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/utils/logger.dart';

final playbackControllerProvider =
    StateNotifierProvider<PlaybackController, PlaybackState>((ref) {
      final audio = ref.watch(audioPlayerServiceProvider);
      final downloads = ref.watch(songDownloadServiceProvider);
      final resolver = ref.watch(streamUrlResolverProvider);
      final store = PlaybackSessionStore(ref.watch(persistenceServiceProvider));
      // The switch decides what a start reads, not what the running player
      // writes, so it is read once when the controller is built.
      final restore = ref
          .read(settingsControllerProvider)
          .restorePlaybackOnStartup;
      return PlaybackController(
        audio,
        downloads,
        resolver,
        sessionStore: store,
        restoreSession: restore,
        deadSongs: ref.watch(deadSongsProvider.notifier),
      );
    });

/// Owns playback and queue state.
///
/// This controller deliberately has no dependency on pages, app bars,
/// notifications, or library widgets. Side effects such as statistics or
/// history belong in listeners outside this class.
class PlaybackController extends StateNotifier<PlaybackState> {
  PlaybackController(
    this._audio,
    this._downloads,
    this._resolver, {
    PlaybackSessionStore? sessionStore,
    bool restoreSession = true,
    DeadSongsController? deadSongs,
  }) : _deadSongs = deadSongs,
       _audioSources = AudioSourceResolver(_downloads),
       _prefetcher = TrackPrefetcher(_downloads),
       _sessionRecorder = sessionStore == null
           ? null
           : PlaybackSessionRecorder(sessionStore),
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
    _restoreSession(restoreSession);

    final recorder = _sessionRecorder;
    if (recorder != null) {
      recorder.start(state);
      _removeSessionListener = addListener((_) => recorder.record(state));
    }
  }

  final AudioPlayerService _audio;
  final SongDownloadService _downloads;
  final StreamUrlResolver _resolver;

  /// The marks of the tracks whose playback failed, if the app keeps them.
  final DeadSongsController? _deadSongs;
  final AudioSourceResolver _audioSources;
  final TrackPrefetcher _prefetcher;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Random _random = Random();

  /// How many times a failing track may get a fresh address.
  static const _maxRefreshAttempts = 1;

  /// How many tracks the playback remembers as its past.
  static const _maxHistory = 50;

  String? _loadedSongUri;
  bool _handlingCompletion = false;
  int _loadRequest = 0;

  /// The order the queue had before it was shuffled.
  ///
  /// It is dropped as soon as the queue is edited, because the order then
  /// describes a queue that no longer exists.
  List<String>? _orderBeforeShuffle;

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

  final PlaybackSessionRecorder? _sessionRecorder;
  void Function()? _removeSessionListener;

  /// The state of the player right now.
  ///
  /// The state of a state holder is protected, so callers outside of the
  /// controller read it through this door.
  PlaybackState get snapshot => state;

  // ---------------------------------------------------------------------------
  // Audio event handlers
  // ---------------------------------------------------------------------------

  /// Whether the audio backend holds the track the state speaks about.
  ///
  /// A restored session has a track and a position but no audio yet. The
  /// backend reports zero for a track it never loaded, so its early events
  /// must not overwrite the position the session brought back.
  bool get _audioHoldsCurrentSong =>
      state.hasTrack && _loadedSongUri == state.currentSong!.uri;

  void _handlePosition(Duration position) {
    if (!mounted || !state.hasTrack || state.hasError) return;
    if (!_audioHoldsCurrentSong) return;
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
    if (!_audioHoldsCurrentSong) return;
    state = state.copyWith(duration: duration);
  }

  void _handlePlaying(bool isPlaying) {
    if (!mounted || !state.hasTrack || state.hasError) return;
    if (!_audioHoldsCurrentSong) return;
    if (state.status == PlaybackStatus.loading) {
      if (isPlaying) {
        state = state.copyWith(status: PlaybackStatus.playing);
        final song = state.currentSong;
        if (song != null) unawaited(_deadSongs?.clear(song.uri));
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
    if (!_audioHoldsCurrentSong) return;

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

  /// Replaces the queue and starts playing [startIndex].
  ///
  /// The queue holds every track only once: the cursor is the identity of a
  /// track, so a track that appears twice would make it ambiguous.
  Future<void> playQueue(List<Song> songs, {int startIndex = 0}) async {
    final playable = <Song>[];
    final seen = <String>{};
    var startUri = '';
    var foundStart = false;
    for (var i = 0; i < songs.length; i++) {
      final song = songs[i];
      if (song.uri.isEmpty) continue;
      if (!seen.add(song.uri)) continue;
      if (!foundStart && i >= startIndex) {
        startUri = song.uri;
        foundStart = true;
      }
      playable.add(song);
    }
    if (playable.isEmpty) return;
    if (!foundStart) startUri = playable.last.uri;

    final queue = List<Song>.unmodifiable(playable);
    final index = queue.indexWhere((song) => song.uri == startUri);
    final song = queue[index];

    _orderBeforeShuffle = null;
    state = state.copyWith(
      queue: queue,
      currentUri: startUri,
      history: const [],
      status: PlaybackStatus.loading,
      position: Duration.zero,
      duration: _knownDuration(song),
      errorMessage: null,
      audioSourceStatus: _initialSourceStatus(song),
      downloadProgress: 0,
    );

    await _startAt(index, recordHistory: false);
  }

  Future<void> playSong(Song song) => playQueue([song]);

  /// Plays a track the user picked and keeps the queue.
  ///
  /// The track joins the queue and starts right away; the tracks that are
  /// queued already keep their place, so the queue grows instead of turning
  /// into a single song.
  Future<void> enqueueAndPlay(Song song) async {
    addToQueue(song);
    final index = state.queue.indexWhere((item) => item.uri == song.uri);
    if (index < 0) return;
    await _startAt(index);
  }

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

  /// Stops the playback but keeps the queue.
  ///
  /// The system media controls ask for a stop that only ends the sound; the
  /// track stays in the queue so it can be started again.
  Future<void> stop() async {
    if (!state.hasTrack) return;
    try {
      await _audio.stop();
      state = state.copyWith(
        status: PlaybackStatus.paused,
        position: Duration.zero,
      );
    } catch (error, stackTrace) {
      _setError(AppStrings.instance.playbackPauseFailed('$error'), stackTrace);
    }
  }

  Future<void> resume() async {
    if (!state.hasTrack) return;

    // A queued track may not have been loaded into the audio backend yet.
    // The saved session is exactly this case: carry its position into the
    // first real load instead of starting the track from zero.
    if (_loadedSongUri != state.currentSong!.uri) {
      await _startAt(state.currentIndex, startPosition: state.position);
      return;
    }

    try {
      await _audio.resume();
      state = state.copyWith(status: PlaybackStatus.playing);
    } catch (error, stackTrace) {
      _setError(AppStrings.instance.playbackResumeFailed('$error'), stackTrace);
    }
  }

  /// Plays the track after the current one.
  ///
  /// The queue holds the play order, so a shuffled queue simply plays on.
  /// The next track is the one the queue hands over to, whatever the mode is.
  Future<void> next() async {
    final queue = state.queue;
    if (queue.isEmpty) return;
    final index = state.currentIndex;
    if (index < 0) {
      await _startAt(0);
      return;
    }
    await _startAt((index + 1) % queue.length);
  }

  /// Goes back to the track that played before.
  ///
  /// The history holds where the playback came from, so a jump is undone
  /// first. Without history the queue decides, which is what a listener
  /// expects while the queue plays in order.
  Future<void> previous() async {
    if (state.queue.isEmpty) return;
    final target = _popHistory();
    if (target != null) {
      await _startAt(target, recordHistory: false);
      return;
    }
    final index = state.currentIndex;
    if (index < 0) {
      await _startAt(0);
      return;
    }
    await _startAt(
      (index - 1 + state.queue.length) % state.queue.length,
      recordHistory: false,
    );
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
      _sessionRecorder?.flushPosition();
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

  /// Switches to the next play mode.
  void cyclePlayMode() {
    final nextMode =
        PlayMode.values[(state.playMode.index + 1) % PlayMode.values.length];
    setPlayMode(nextMode);
  }

  /// Sets how the queue plays.
  ///
  /// Switching to shuffle rearranges the queue once, so the list the user
  /// sees is the order that plays. Switching back restores the order the
  /// queue had before, unless the queue was edited in the meantime.
  ///
  /// The system media controls switch the random order and the repeat mode on
  /// their own, so the mode is set directly instead of being cycled.
  void setPlayMode(PlayMode mode) {
    if (state.playMode == mode) return;
    var queue = state.queue;
    if (mode == PlayMode.shuffle) {
      queue = _shuffledQueue();
    } else if (state.playMode == PlayMode.shuffle) {
      queue = _restoredQueue();
    }
    state = state.copyWith(queue: queue, playMode: mode);
  }

  // ---------------------------------------------------------------------------
  // Queue API
  // ---------------------------------------------------------------------------

  void addToQueue(Song song) {
    if (song.uri.isEmpty) return;
    if (state.queue.any((item) => item.uri == song.uri)) return;

    final queue = List<Song>.unmodifiable([...state.queue, song]);
    _orderBeforeShuffle = null;
    if (!state.hasTrack) {
      state = state.copyWith(
        queue: queue,
        currentUri: song.uri,
        status: PlaybackStatus.paused,
        duration: _knownDuration(song),
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(queue: queue);
  }

  /// Adds every track of [songs] to the queue.
  ///
  /// The whole list goes in at once, so a library with thousands of tracks
  /// does not rebuild the queue thousands of times. Tracks that are queued
  /// already are left out.
  ///
  /// Returns how many tracks were added.
  int addAllToQueue(List<Song> songs) {
    final queued = state.queue.map((song) => song.uri).toSet();
    final additions = <Song>[];
    for (final song in songs) {
      if (song.uri.isEmpty) continue;
      if (!queued.add(song.uri)) continue;
      additions.add(song);
    }
    if (additions.isEmpty) return 0;

    final queue = List<Song>.unmodifiable([...state.queue, ...additions]);
    _orderBeforeShuffle = null;
    if (!state.hasTrack) {
      state = state.copyWith(
        queue: queue,
        currentUri: additions.first.uri,
        status: PlaybackStatus.paused,
        duration: _knownDuration(additions.first),
        errorMessage: null,
      );
      return additions.length;
    }

    state = state.copyWith(queue: queue);
    return additions.length;
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= state.queue.length) return;

    final wasPlaying = state.isPlaying;
    final removingCurrent = index == state.currentIndex;
    final removed = state.queue[index];
    final queue = List<Song>.of(state.queue)..removeAt(index);
    _orderBeforeShuffle = null;
    if (queue.isEmpty) {
      await clearQueue();
      return;
    }

    // A removed track must not come back through the history.
    final history = state.history
        .where((uri) => uri != removed.uri)
        .toList(growable: false);

    if (!removingCurrent) {
      // The prefetch of a track that left the queue is not needed anymore.
      _prefetcher.stopIf(removed);
      state = state.copyWith(
        queue: List<Song>.unmodifiable(queue),
        history: history,
      );
      return;
    }

    final nextIndex = index >= queue.length ? queue.length - 1 : index;
    final nextSong = queue[nextIndex];
    state = state.copyWith(
      queue: List<Song>.unmodifiable(queue),
      history: history,
      currentUri: nextSong.uri,
      status: PlaybackStatus.paused,
      position: Duration.zero,
      duration: _knownDuration(nextSong),
      errorMessage: null,
    );
    _loadedSongUri = null;

    if (wasPlaying) {
      await _startAt(nextIndex, recordHistory: false);
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

    final queue = List<Song>.of(state.queue);
    final moved = queue.removeAt(oldIndex);
    queue.insert(targetIndex, moved);
    _orderBeforeShuffle = null;

    state = state.copyWith(queue: List<Song>.unmodifiable(queue));
  }

  Future<void> clearQueue() async {
    _loadRequest++;
    _prefetcher.stop();
    _orderBeforeShuffle = null;
    try {
      await _audio.stop();
    } catch (error, stackTrace) {
      Log.error('停止播放失败: $error\n$stackTrace');
    }

    _loadedSongUri = null;
    state = state.copyWith(
      status: PlaybackStatus.idle,
      position: Duration.zero,
      duration: Duration.zero,
      queue: const [],
      currentUri: null,
      history: const [],
      errorMessage: null,
      audioSourceStatus: AudioSourceStatus.local,
      downloadProgress: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Session persistence
  // ---------------------------------------------------------------------------

  /// Loads the queue the last run left behind, paused at its position.
  void _restoreSession(bool restore) {
    final recorder = _sessionRecorder;
    if (recorder == null) return;

    if (restore) {
      final session = recorder.read();
      if (session != null) {
        final song = session.currentSong;
        state = PlaybackState(
          status: PlaybackStatus.paused,
          position: song.isLiveStream ? Duration.zero : session.position,
          duration: _knownDuration(song),
          volume: state.volume,
          playMode: session.playMode,
          queue: session.queue,
          currentUri: session.currentUri,
          history: session.history,
          audioSourceStatus: _initialSourceStatus(song),
        );
      }
    }

    final volume = recorder.readVolume();
    if (volume != state.volume) {
      state = state.copyWith(volume: volume);
    }
    unawaited(_applyVolume(volume));
  }

  Future<void> _applyVolume(double volume) async {
    try {
      await _audio.setVolume(volume);
    } catch (error, stackTrace) {
      Log.error('恢复音量失败: $error\n$stackTrace');
    }
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
  ///
  /// [recordHistory] tells whether the track the playback came from belongs
  /// into the history. A track that is left behind on purpose does not.
  Future<void> _startAt(
    int index, {
    bool isRetry = false,
    bool recordHistory = true,
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
      currentUri: song.uri,
      status: PlaybackStatus.loading,
      position: startPosition,
      duration: _knownDuration(song),
      errorMessage: null,
      audioSourceStatus: _initialSourceStatus(song),
      downloadProgress: 0,
      history: _historyAfterSwitch(song.uri, recordHistory),
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
      status: _audio.isPlaying ? PlaybackStatus.playing : PlaybackStatus.paused,
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
      // The track stays in the library; the row only carries a mark.
      unawaited(_deadSongs?.markFailed(song.uri));
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
    if (song.localPath != null) {
      // The track was fetched, so its copy on this machine is what plays.
      return AudioSourceStatus.cached;
    }
    return song.isRemote
        ? AudioSourceStatus.streaming
        : AudioSourceStatus.local;
  }

  /// The history after the playback moved to [nextUri].
  ///
  /// The track the playback came from is remembered, so the previous button
  /// can lead back to it. A track that stays the same is not a switch.
  List<String> _historyAfterSwitch(String nextUri, bool record) {
    final previousUri = state.currentUri;
    if (!record || previousUri == null || previousUri == nextUri) {
      return state.history;
    }
    final history = [...state.history, previousUri];
    if (history.length > _maxHistory) {
      history.removeRange(0, history.length - _maxHistory);
    }
    return List<String>.unmodifiable(history);
  }

  /// The track the previous button leads back to.
  ///
  /// Entries whose track left the queue are dropped: a deleted track must
  /// not come back.
  int? _popHistory() {
    final remaining = List<String>.of(state.history);
    var target = -1;
    while (target < 0 && remaining.isNotEmpty) {
      final uri = remaining.removeLast();
      final index = state.queue.indexWhere((song) => song.uri == uri);
      if (index >= 0) target = index;
    }
    state = state.copyWith(history: List<String>.unmodifiable(remaining));
    return target < 0 ? null : target;
  }

  /// The queue with a new random order, so the list the user sees is the
  /// order that plays.
  List<Song> _shuffledQueue() {
    final queue = List<Song>.of(state.queue);
    if (queue.length < 2) return List<Song>.unmodifiable(queue);

    _orderBeforeShuffle = queue.map((song) => song.uri).toList();
    for (var i = queue.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final moved = queue[i];
      queue[i] = queue[j];
      queue[j] = moved;
    }
    return List<Song>.unmodifiable(queue);
  }

  /// The queue in the order it had before the shuffle.
  ///
  /// The order is only restored when the queue still holds the same tracks:
  /// an edited queue keeps the order the user gave it.
  List<Song> _restoredQueue() {
    final order = _orderBeforeShuffle;
    _orderBeforeShuffle = null;
    if (order == null) return state.queue;

    final byUri = {for (final song in state.queue) song.uri: song};
    final restored = <Song>[];
    for (final uri in order) {
      final song = byUri[uri];
      if (song == null) return state.queue;
      restored.add(song);
    }
    return List<Song>.unmodifiable(restored);
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
    _removeSessionListener?.call();
    _removeSessionListener = null;
    _sessionRecorder?.close();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
