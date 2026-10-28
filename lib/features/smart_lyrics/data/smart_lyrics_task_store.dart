import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_task.dart';

/// The batch queue of the smart lyrics pipeline (docs/smart-lyrics.md
/// §7.2, M5): the tracks the three segments brought no words for, in the
/// order the batch keeps — a marked track first, and within one group a
/// stable order an interrupted run can resume against.
class SmartLyricsTaskStore {
  SmartLyricsTaskStore({Future<AppDatabase> Function()? database})
    : _databaseFactory = database;

  final Future<AppDatabase> Function()? _databaseFactory;

  AppDatabase? _database;

  Future<AppDatabase> _db() async {
    final existing = _database;
    if (existing != null) return existing;

    final factory = _databaseFactory;
    final database = factory != null ? await factory() : await _openDefault();
    _database = database;
    return database;
  }

  Future<AppDatabase> _openDefault() async {
    // The same file the library and the ledger read: one database holds
    // the app's index, and the batch is one more set of rows in it.
    final base = await getApplicationSupportDirectory();
    final directory = Directory(path.join(base.path, 'library'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return AppDatabase.open(path.join(directory.path, 'library.db'));
  }

  /// Puts every active track that carries no lyrics into the queue;
  /// answers how many rows the press added.
  Future<int> enqueueMissing() async =>
      (await _db()).enqueueMissingTasks(now: _now());

  /// The gap tracks a scan brought in that are not queued yet — the card
  /// says so; the queue only moves on a press.
  Future<int> newMissing() async => (await _db()).countNewMissingTasks();

  /// The next track to run, read whole; `null` when the queue is empty.
  Future<Song?> nextPending() async {
    final database = await _db();
    final next = database.nextPendingTask();
    if (next == null) return null;
    return database.songWithId(next.songId);
  }

  /// A run is on [songId] now; the attempt is counted.
  Future<void> markRunning(int songId) async {
    (await _db()).beginTaskRun(songId, now: _now());
  }

  /// A run was stopped on [songId]: the task waits in line again, and the
  /// next run picks it up with the rest.
  Future<void> markPending(int songId) async {
    (await _db()).setTaskOutcome(
      songId,
      SmartLyricsTaskStatus.pending.id,
      now: _now(),
    );
  }

  /// The pool agreed; the sheet sits next to the audio.
  Future<void> markDone(int songId, {required int votes, int disputed = 0}) async {
    (await _db()).setTaskOutcome(
      songId,
      SmartLyricsTaskStatus.done.id,
      votes: votes,
      disputed: disputed,
      now: _now(),
    );
  }

  /// Lines were left in dispute — the settled part is on the disk, the
  /// rest waits for a re-solve.
  Future<void> markDisputed(int songId, {required int votes}) async {
    (await _db()).setTaskOutcome(
      songId,
      SmartLyricsTaskStatus.disputed.id,
      votes: votes,
      now: _now(),
    );
  }

  /// The pool heard no voice; the track is not a gap.
  Future<void> markInstrumental(int songId) async {
    (await _db()).setTaskOutcome(
      songId,
      SmartLyricsTaskStatus.instrumental.id,
      now: _now(),
    );
  }

  /// The run failed; the track waits for an explicit retry.
  Future<void> markFailed(int songId, {required String error}) async {
    (await _db()).setTaskOutcome(
      songId,
      SmartLyricsTaskStatus.failed.id,
      error: error,
      now: _now(),
    );
  }

  /// The tasks by their status, for the card.
  Future<Map<SmartLyricsTaskStatus, int>> counts() async {
    final rows = (await _db()).taskStatusCounts();
    return {
      for (final row in rows)
        if (SmartLyricsTaskStatus.values.any((status) => status.id == row.status))
          SmartLyricsTaskStatus.values.byName(row.status): row.count,
    };
  }

  /// Puts every failed task back in line for a recheck; the action the
  /// card offers after a new source or a new model was configured.
  Future<int> requeueFailed() async =>
      (await _db()).requeueFailedTasks(now: _now());

  /// Records a mark on a track: the batch runs the marked tracks first.
  Future<void> recordMark(int songId) async {
    (await _db()).recordSongMark(songId, source: 'system', now: _now());
  }

  static int _now() => DateTime.now().millisecondsSinceEpoch;
}
