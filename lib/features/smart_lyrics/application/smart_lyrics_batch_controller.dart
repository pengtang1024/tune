import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_controller.dart';
import 'package:tune/features/smart_lyrics/data/smart_lyrics_task_store.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_task.dart';
import 'package:tune/utils/logger.dart';

/// The store the batch queue reads through and writes to.
final smartLyricsTaskStoreProvider = Provider<SmartLyricsTaskStore>(
  (ref) => SmartLyricsTaskStore(),
);

/// The gap tracks a scan brought in that are not queued yet — the card
/// says so; the queue only moves when the reader presses the button. The
/// count follows the identity of the library window like the ledger does.
final smartLyricsNewMissingProvider = FutureProvider<int>((ref) async {
  ref.watch(
    libraryControllerProvider.select((state) => state.valueOrNull?.songs),
  );
  return ref.watch(smartLyricsTaskStoreProvider).newMissing();
});

/// The account of the tasks as they stand: one query over the rows, the
/// way the ledger counts. A run invalidates it when it ends, so the card
/// follows without a notifier holding the figures.
final smartLyricsBatchCountsProvider = FutureProvider<
  Map<SmartLyricsTaskStatus, int>
>((ref) async {
  ref.watch(
    libraryControllerProvider.select((state) => state.valueOrNull?.songs),
  );
  return ref.watch(smartLyricsTaskStoreProvider).counts();
});

/// The pause between two tracks of a batch (docs/smart-lyrics.md §7.2):
/// the run breathes between songs so it never fights the player for the
/// machine. Tests set it to zero.
final smartLyricsBatchGapProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 2),
);

/// How a batch run stands while it stands.
final smartLyricsBatchControllerProvider =
    NotifierProvider<SmartLyricsBatchController, SmartLyricsBatchProgress>(
      SmartLyricsBatchController.new,
    );

/// The batch worker (docs/smart-lyrics.md §7.2, M5): one track at a time,
/// through the same single-song pipeline the panel button presses — a
/// failure never stops the ones behind it, the cloud budget pauses the run
/// without losing the queue, and an interrupted run resumes where it stood.
class SmartLyricsBatchController extends Notifier<SmartLyricsBatchProgress> {
  bool _stopped = false;

  @override
  SmartLyricsBatchProgress build() {
    // The card mounts with the account of the tasks as they stand; a run
    // overwrites it with its own figures.
    return SmartLyricsBatchProgress.idle;
  }

  /// Enqueues the tracks the three segments brought no words for, and runs
  /// them until the queue is empty, the reader stops it, or the cloud
  /// budget is spent.
  Future<void> start() async {
    if (state.running) return;
    _stopped = false;
    final store = ref.read(smartLyricsTaskStoreProvider);
    await store.enqueueMissing();
    await _drain(store);
  }

  /// Puts the failed tasks back in line and runs them — the action after
  /// a new source or a new model was configured.
  Future<void> retryFailed() async {
    if (state.running) return;
    _stopped = false;
    final store = ref.read(smartLyricsTaskStoreProvider);
    await store.requeueFailed();
    await _drain(store);
  }

  /// Stops between two tracks; the track in flight is stopped with the
  /// single-song cancel, and its task goes back to pending.
  void stop() => _stopped = true;

  Future<void> _drain(SmartLyricsTaskStore store) async {
    final service = ref.read(smartLyricsServiceProvider);
    final budget = ref.read(
      settingsControllerProvider.select((state) => state.smartLyrics),
    ).batchCloudBudget;
    var cloudUsed = 0;

    state = SmartLyricsBatchProgress(
      running: true,
      counts: await store.counts(),
      cloudUsed: cloudUsed,
      cloudBudget: budget > 0 ? budget : null,
    );

    while (true) {
      if (_stopped) break;
      final next = await store.nextPending();
      if (next == null) break;

      await store.markRunning(next.id);
      state = SmartLyricsBatchProgress(
        running: true,
        currentSongId: next.id,
        counts: await store.counts(),
        cloudUsed: cloudUsed,
        cloudBudget: budget > 0 ? budget : null,
      );

      try {
        final outcome = await service.generate(next, cancelled: () => _stopped);
        if (_stopped || outcome.cancelled) {
          await store.markPending(next.id);
          break;
        }
        await _write(store, next, outcome);
        if (_usesCloud(outcome)) cloudUsed++;
      } catch (error, stackTrace) {
        Log.error('批量单曲失败: $error', stackTrace);
        await store.markFailed(next.id, error: '$error');
      }

      if (budget > 0 && cloudUsed >= budget) break;
      final gap = ref.read(smartLyricsBatchGapProvider);
      if (gap > Duration.zero) await Future<void>.delayed(gap);
    }

    state = SmartLyricsBatchProgress(
      running: false,
      counts: await store.counts(),
      cloudUsed: cloudUsed,
      cloudBudget: budget > 0 ? budget : null,
    );
    // The figures on the card follow the run, without the notifier
    // becoming a second account of them.
    ref.invalidate(smartLyricsBatchCountsProvider);
  }

  /// How a run ended, as the task table reads it: the sheet on the disk
  /// stands for done, the disputed part for a re-solve, silence for
  ///「不是唱的」, and every failure for an explicit retry.
  Future<void> _write(
    SmartLyricsTaskStore store,
    Song song,
    SmartLyricsOutcome outcome,
  ) async {
    if (outcome.saved && outcome.disputed > 0) {
      await store.markDisputed(song.id, votes: outcome.votes);
    } else if (outcome.saved) {
      await store.markDone(song.id, votes: outcome.votes);
    } else if (outcome.failure == SmartLyricsFailure.emptyResult) {
      await store.markInstrumental(song.id);
    } else {
      await store.markFailed(song.id, error: '${outcome.failure}');
    }
  }

  /// Whether the run spent the cloud: a song the free votes could settle
  /// costs nothing.
  bool _usesCloud(SmartLyricsOutcome outcome) => outcome.origins.any(
    (origin) => origin.startsWith('cloud:'),
  );
}
