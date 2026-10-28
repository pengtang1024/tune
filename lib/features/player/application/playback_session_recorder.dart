import 'dart:async';

import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/data/playback_session_store.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_session.dart';
import 'package:tune/features/player/domain/playback_state.dart';
import 'package:tune/utils/logger.dart';

/// Writes the playback session while the player runs.
///
/// The controller owns the state; this class only watches it. The queue and
/// the position have different rhythms, so they get separate timers: a queue
/// edit waits a moment for the next edit, while the position is written every
/// few seconds. Pausing, switching tracks and seeking write the position right
/// away.
class PlaybackSessionRecorder {
  PlaybackSessionRecorder(this._store);

  final PlaybackSessionStore _store;

  Timer? _queueSaveTimer;
  Timer? _positionSaveTimer;
  Timer? _volumeSaveTimer;

  PlaybackState _state = PlaybackState.initial;

  /// The last values written to the store, so a state change only saves the
  /// part that actually changed.
  List<Song> _lastQueue = const [];
  String? _lastUri;
  PlayMode _lastMode = PlayMode.sequential;
  List<String> _lastHistory = const [];
  Duration _lastPosition = Duration.zero;
  double _lastVolume = 1.0;
  PlaybackStatus _lastStatus = PlaybackStatus.idle;

  /// Whether the reader changed the session in this run.
  ///
  /// A start that found no session is empty on purpose; it must not
  /// erase a session that is still being read — a broken document, for
  /// example, stays until the reader plays or edits the queue.
  bool _dirty = false;

  PlaybackSession? read() => _store.readSession();

  double readVolume() => _store.readVolume();

  /// Takes the state the controller restored as the baseline.
  void start(PlaybackState state) {
    _state = state;
    _lastQueue = state.queue;
    _lastUri = state.currentUri;
    _lastMode = state.playMode;
    _lastHistory = state.history;
    _lastPosition = state.position;
    _lastVolume = state.volume;
    _lastStatus = state.status;
    _dirty = false;
  }

  /// Notes a new state and schedules the parts that need saving.
  void record(PlaybackState state) {
    _state = state;
    final queueChanged =
        !identical(state.queue, _lastQueue) ||
        state.currentUri != _lastUri ||
        state.playMode != _lastMode ||
        !identical(state.history, _lastHistory);

    if (queueChanged) {
      _dirty = true;
      _lastQueue = state.queue;
      _lastUri = state.currentUri;
      _lastMode = state.playMode;
      _lastHistory = state.history;
      _scheduleQueueSave();
      flushPosition();
    }

    if (state.position != _lastPosition) {
      _lastPosition = state.position;
      _schedulePositionSave();
    }

    if (state.volume != _lastVolume) {
      _lastVolume = state.volume;
      _scheduleVolumeSave();
    }

    if (state.status == PlaybackStatus.paused &&
        _lastStatus != PlaybackStatus.paused) {
      flushPosition();
    }
    _lastStatus = state.status;
  }

  /// Writes the position now; pausing, seeking and switching tracks use it.
  void flushPosition() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = null;
    unawaited(_writePosition());
  }

  /// Flushes the session and stops the timers.
  void close() {
    _queueSaveTimer?.cancel();
    _positionSaveTimer?.cancel();
    _volumeSaveTimer?.cancel();
    _queueSaveTimer = null;
    _positionSaveTimer = null;
    _volumeSaveTimer = null;

    if (_dirty || _state.queue.isNotEmpty) {
      unawaited(_writeQueue());
    }
    if (_dirty || _state.hasTrack) {
      unawaited(_writePosition());
    }
    unawaited(_writeVolume());
  }

  void _scheduleQueueSave() {
    _queueSaveTimer?.cancel();
    _queueSaveTimer = Timer(const Duration(milliseconds: 600), () {
      _queueSaveTimer = null;
      unawaited(_writeQueue());
    });
  }

  void _schedulePositionSave() {
    _positionSaveTimer ??= Timer(const Duration(seconds: 5), () {
      _positionSaveTimer = null;
      unawaited(_writePosition());
    });
  }

  void _scheduleVolumeSave() {
    _volumeSaveTimer?.cancel();
    _volumeSaveTimer = Timer(const Duration(milliseconds: 500), () {
      _volumeSaveTimer = null;
      unawaited(_writeVolume());
    });
  }

  Future<void> _writeQueue() async {
    try {
      final uri = _state.currentUri;
      if (uri == null || _state.queue.isEmpty) {
        await _store.clearSession();
        return;
      }
      await _store.saveQueue(
        queue: _state.queue,
        currentUri: uri,
        playMode: _state.playMode,
        history: _state.history,
      );
    } catch (error, stackTrace) {
      Log.error('保存播放队列失败: $error\n$stackTrace');
    }
  }

  Future<void> _writePosition() async {
    try {
      final uri = _state.currentUri;
      if (uri == null) {
        await _store.clearPosition();
        return;
      }
      final song = _state.currentSong;
      final position = song?.isLiveStream ?? false
          ? Duration.zero
          : _state.position;
      await _store.savePosition(uri, position);
    } catch (error, stackTrace) {
      Log.error('保存播放位置失败: $error\n$stackTrace');
    }
  }

  Future<void> _writeVolume() async {
    try {
      await _store.saveVolume(_state.volume);
    } catch (error, stackTrace) {
      Log.error('保存音量失败: $error\n$stackTrace');
    }
  }
}
