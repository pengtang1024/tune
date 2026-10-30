import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/app_database_provider.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_service.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_run_lock.dart';
import 'package:tune/features/smart_lyrics/data/smart_lyrics_task_store.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_task.dart';
import 'package:tune/utils/logger.dart';

/// The store the batch queue reads through and writes to.
final smartLyricsTaskStoreProvider = Provider<SmartLyricsTaskStore>(
  // The one connection the library also reads: the task rows and the song
  // rows are the same file, and a second connection would compete for its
  // lock.
  (ref) => SmartLyricsTaskStore(
    database: () => ref.read(appDatabaseProvider.future),
  ),
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

/// How many songs the batch may work on at once. Downloads and CPU
/// overlap; six keeps a slow host from parking the whole queue.
final smartLyricsBatchWorkersProvider = Provider<int>((ref) => 6);

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
    final lock = ref.read(smartLyricsRunLockProvider);
    if (!lock.claimBatch()) return;
    _stopped = false;
    final store = ref.read(smartLyricsTaskStoreProvider);
    try {
      // A dead run leaves its task `running` and a transient failure
      // leaves it `failed`; the automatic pass revives both so the
      // library reaches 100% without a press. A task that burned five
      // attempts waits for the reader's explicit retry.
      await store.requeueInterrupted();
      await store.enqueueMissing();
      await store.requeueFailed(maxAttempts: 5);
      await _drain(store);
    } catch (error, stackTrace) {
      Log.error('批量运行失败: $error', stackTrace);
      state = const SmartLyricsBatchProgress(running: false, counts: {});
    } finally {
      lock.releaseBatch();
    }
  }

  /// Puts the failed tasks back in line and runs them — the action after
  /// a new source or a new model was configured.
  Future<void> retryFailed() async {
    if (state.running) return;
    final lock = ref.read(smartLyricsRunLockProvider);
    if (!lock.claimBatch()) return;
    _stopped = false;
    final store = ref.read(smartLyricsTaskStoreProvider);
    try {
      await store.requeueInterrupted();
      await store.requeueFailed();
      await _drain(store);
    } catch (error, stackTrace) {
      Log.error('批量重试失败: $error', stackTrace);
      state = const SmartLyricsBatchProgress(running: false, counts: {});
    } finally {
      lock.releaseBatch();
    }
  }

  /// Stops between two tracks; the track in flight is stopped with the
  /// single-song cancel, and its task goes back to pending.
  void stop() => _stopped = true;

  Future<void> _drain(SmartLyricsTaskStore store) async {
    final budget = ref.read(
      settingsControllerProvider.select(
        (state) => state.smartLyrics.batchCloudBudget,
      ),
    );
    final workers = ref.read(smartLyricsBatchWorkersProvider).clamp(1, 6);
    var cloudUsed = 0;
    var budgetReached = false;

    state = SmartLyricsBatchProgress(
      running: true,
      counts: await store.counts(),
      cloudUsed: cloudUsed,
      cloudBudget: budget > 0 ? budget : null,
    );

    Future<void> runWorker(int slot) async {
      final service = slot == 0
          ? ref.read(smartLyricsServiceProvider)
          : ref.read(smartLyricsWorkerServiceProvider(slot));
      while (true) {
        if (_stopped || budgetReached) break;
        final next = await store.claimNext();
        if (next == null) break;
        if (_stopped) {
          await store.markPending(next.id);
          break;
        }
        state = SmartLyricsBatchProgress(
          running: true,
          currentSongId: next.id,
          counts: state.counts,
          cloudUsed: cloudUsed,
          cloudBudget: budget > 0 ? budget : null,
          progress: 0,
        );

        try {
          var lastProgress = -1.0;
          final outcome = await service.generate(
            next,
            cancelled: () => _stopped,
            onProgress: (value) {
              // A whisper pass reports often; two percent is enough for
              // the bar without rebuilding the card on every line.
              if (value - lastProgress < 0.02 && value < 1) return;
              lastProgress = value;
              state = SmartLyricsBatchProgress(
                running: true,
                currentSongId: next.id,
                counts: state.counts,
                cloudUsed: cloudUsed,
                cloudBudget: budget > 0 ? budget : null,
                progress: value,
              );
            },
          );
          if (_stopped || outcome.cancelled) {
            await store.markPending(next.id);
            break;
          }
          await store.applyOutcome(next, outcome);
          if (outcome.saved) refreshLyricsPanel(ref, next);
          if (_usesCloud(outcome)) cloudUsed++;
        } catch (error, stackTrace) {
          Log.error('批量单曲失败: $error', stackTrace);
          await store.markFailed(next.id, error: '$error');
        }

        if (budget > 0 && cloudUsed >= budget) {
          budgetReached = true;
          break;
        }
        final gap = ref.read(smartLyricsBatchGapProvider);
        if (gap > Duration.zero) await Future<void>.delayed(gap);
      }
    }

    await Future.wait([
      for (var slot = 0; slot < workers; slot++) runWorker(slot),
    ]);

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

  /// Whether the run spent money: a cloud ASR vote or a knowledge rebuild
  /// both leave the machine. A song the free votes could settle costs
  /// nothing.
  bool _usesCloud(SmartLyricsOutcome outcome) => outcome.origins.any(
    (origin) =>
        origin.startsWith('cloud:') || origin.startsWith('knowledge:'),
  );
}
