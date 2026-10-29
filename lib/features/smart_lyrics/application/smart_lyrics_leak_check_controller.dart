import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/library_paths_provider.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_service.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_batch_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_controller.dart';
import 'package:tune/utils/logger.dart';

/// The pipeline without any channels (docs/smart-lyrics.md §7.2): the free
/// check asks the human pool alone — no ASR, no cloud, no CPU. A song the
/// pool cannot settle now keeps the task it had; a sheet the pool grew in
/// the meantime goes through the same consensus the panel button presses.
final smartLyricsHumanOnlyServiceProvider = Provider<SmartLyricsService>((
  ref,
) {
  final sources = ref.watch(musicSourceServiceProvider);
  final paths = ref.watch(libraryPathsProvider);
  return SmartLyricsService(
    engines: const [],
    humanPool: [(name: 'lrclib', provider: sources.lyricsProvider)],
    paths: paths,
    health: ref.watch(smartLyricsChannelHealthProvider),
  );
});

/// How long a quiet stretch is before the free check looks again.
final smartLyricsLeakCheckIntervalProvider = Provider<Duration>(
  (ref) => const Duration(hours: 6),
);

/// The free check itself; the app starts it once at boot.
final smartLyricsLeakCheckControllerProvider =
    Provider<SmartLyricsLeakCheckController>((ref) {
      final controller = SmartLyricsLeakCheckController(ref);
      ref.onDispose(controller.dispose);
      return controller;
    });

/// The periodic re-ask of the human pool (docs/smart-lyrics.md §7.2, M5).
///
/// The loop starts where the app boots, and every tick acts only when the
/// machine is quiet — nothing playing, no batch running. The pool grows
/// over the years; a dead account today is a song with words later, and
/// this is the door it comes back through.
class SmartLyricsLeakCheckController {
  final Ref _ref;

  Timer? _timer;
  bool _busy = false;

  SmartLyricsLeakCheckController(this._ref);

  /// Starts the periodic check; the app calls this once.
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(
      _ref.read(smartLyricsLeakCheckIntervalProvider),
      (_) => unawaited(_tick()),
    );
  }

  void dispose() => _timer?.cancel();

  Future<void> _tick() async {
    if (_busy) return;
    final enabled = _ref.read(
      settingsControllerProvider.select(
        (state) => state.smartLyrics.gapCheckEnabled,
      ),
    );
    if (!enabled) return;
    if (_ref.read(smartLyricsBatchControllerProvider).running) return;
    final playing = _ref.read(
      playbackControllerProvider.select((state) => state.currentSong),
    );
    if (playing != null) return;

    _busy = true;
    try {
      await runOnce();
    } finally {
      _busy = false;
    }
  }

  /// One pass over the dead accounts (docs/smart-lyrics.md §7.2): every
  /// candidate gets one free vote asked of the human pool.
  Future<void> runOnce() async {
    final store = _ref.read(smartLyricsTaskStoreProvider);
    final service = _ref.read(smartLyricsHumanOnlyServiceProvider);
    final candidates = await store.leakyCandidates();

    for (final song in candidates) {
      try {
        final outcome = await service.generate(song);
        // A pass that found nothing new leaves the task as it stood: the
        // dead account is still dead, and the reason it had is still
        // readable. Only a real answer — the sheet, or the pool hearing
        // no voice — moves the status.
        if (outcome.saved ||
            outcome.failure == SmartLyricsFailure.emptyResult) {
          await store.applyOutcome(song, outcome);
        }
      } catch (error, stackTrace) {
        Log.error('查漏单曲失败: $error', stackTrace);
      }
    }

    if (candidates.isNotEmpty) {
      _ref.invalidate(smartLyricsBatchCountsProvider);
    }
  }
}
