import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/features/discovery/application/discovery_providers.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/playback_state.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/utils/logger.dart';

final discoverySignalObserverProvider = Provider<DiscoverySignalObserver>((
  ref,
) {
  return DiscoverySignalObserver(ref);
});

/// Turns playback into the small aggregates the discover page learns from.
///
/// The observer sits outside the player: it watches the public state, decides
/// whether a track was listened to or skipped, and writes the aggregate to
/// its own store. Turning the setting off stops all writing immediately.
class DiscoverySignalObserver {
  DiscoverySignalObserver(this._ref);

  final Ref _ref;

  bool _started = false;
  bool _enabled = false;

  /// The position where listening for the current track started.
  ///
  /// It is zero for a normal track start. When the reader turns the setting
  /// on in the middle of a track, the part before the switch is not counted.
  int _floorMs = 0;

  Future<void> _writing = Future<void>.value();

  void start() {
    if (_started) return;
    _started = true;
    _enabled = _ref.read(settingsControllerProvider).useListeningHistory;
    if (_enabled) {
      _floorMs = 0;
    }

    _ref.listen<PlaybackState>(playbackControllerProvider, _onPlayback);
    _ref.listen<bool>(
      settingsControllerProvider.select((state) => state.useListeningHistory),
      (previous, next) => _onSetting(next),
    );
  }

  void _onSetting(bool enabled) {
    if (_enabled == enabled) return;
    _enabled = enabled;
    if (enabled) {
      // Start counting from now, not from the beginning of the track that
      // happened to be playing when the switch was turned on.
      _floorMs = _ref.read(playbackControllerProvider).position.inMilliseconds;
    } else {
      _floorMs = 0;
    }
  }

  void _onPlayback(PlaybackState? previous, PlaybackState next) {
    if (!_enabled) return;
    if (previous == null) {
      _floorMs = 0;
      return;
    }
    if (previous.currentUri == next.currentUri) return;

    final oldUri = previous.currentUri;
    if (oldUri != null && previous.currentSong?.isLiveStream != true) {
      _settle(previous);
    }
    _floorMs = 0;
  }

  void _settle(PlaybackState state) {
    final uri = state.currentUri;
    if (uri == null || uri.isEmpty) return;
    // A paused track that is switched away was not listened to; it is also
    // not a skip, because the reader stopped it on purpose.
    if (state.status != PlaybackStatus.playing) return;

    final durationMs = state.duration.inMilliseconds;
    final listenedMs = (state.position.inMilliseconds - _floorMs).clamp(
      0,
      durationMs > 0 ? durationMs : 24 * 60 * 60 * 1000,
    );
    final thresholdMs = durationMs > 0
        ? math.min(45000, durationMs * 0.5).toInt()
        : 45000;
    final store = _ref.read(listeningSignalStoreProvider);

    if (listenedMs < thresholdMs) {
      _enqueue(() => store.recordSkip(uri));
      return;
    }
    final completed =
        durationMs > 0 && state.position.inMilliseconds >= durationMs * 0.95;
    _enqueue(
      () => store.recordListen(
        uri,
        listened: Duration(milliseconds: listenedMs),
        completed: completed,
      ),
    );
  }

  /// Waits until the writes already scheduled have reached the store.
  Future<void> flush() => _writing;

  void _enqueue(Future<void> Function() action) {
    _writing = _writing.then((_) => action()).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      Log.error('写入播放记录失败: $error\n$stackTrace');
    });
  }
}
