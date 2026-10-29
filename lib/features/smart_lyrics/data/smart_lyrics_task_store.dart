import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_mark.dart';
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

  /// The tracks the free check may revive: the failed and the disputed
  /// ones, a batch at a time.
  Future<List<Song>> leakyCandidates({int limit = 50}) async =>
      (await _db()).leakySongs(limit: limit);

  /// How a run ended, as the task table reads it — the same mapping for
  /// the batch and for the free check: the sheet on the disk stands for
  /// done, the disputed part for a re-solve, silence for「不是唱的」, and
  /// every failure for an explicit retry.
  Future<void> applyOutcome(Song song, SmartLyricsOutcome outcome) async {
    if (outcome.saved) await settleMarks(song, outcome);
    if (outcome.saved && outcome.disputed > 0) {
      await markDisputed(song.id, votes: outcome.votes);
    } else if (outcome.saved) {
      await markDone(song.id, votes: outcome.votes);
    } else if (outcome.failure == SmartLyricsFailure.emptyResult) {
      await markInstrumental(song.id);
    } else {
      await markFailed(song.id, error: '${outcome.failure}');
    }
  }

  /// The marks a saved run answered: the open ones settle as resolved —
  /// they stay on record, never dangle — and the lines the pool still
  /// cannot agree on become fresh system marks (docs/smart-lyrics.md §7.4).
  Future<void> settleMarks(Song song, SmartLyricsOutcome outcome) async {
    final database = await _db();
    final now = _now();
    database.resolveMarkRows(song.id, now: now);
    for (final line in outcome.disputedLines) {
      database.addMarkRow(
        songId: song.id,
        line: line,
        kind: SmartLyricsMarkKind.line.id,
        source: 'system',
        now: now,
      );
    }
  }

  /// Marks one line of a track wrong: the reader heard it, or the pool
  /// left it in dispute. The track goes back in line for a re-solve.
  Future<void> markLine(
    int songId,
    int line, {
    String source = 'reader',
  }) async {
    final database = await _db();
    final now = _now();
    database.addMarkRow(
      songId: songId,
      line: line,
      kind: SmartLyricsMarkKind.line.id,
      source: source,
      now: now,
    );
    database.requeueSongTask(songId, now: now);
  }

  /// Marks the whole track wrong; the re-solve hears it again.
  Future<void> markSong(int songId, {String source = 'reader'}) async {
    final database = await _db();
    final now = _now();
    database.addMarkRow(
      songId: songId,
      kind: SmartLyricsMarkKind.song.id,
      source: source,
      now: now,
    );
    database.requeueSongTask(songId, now: now);
  }

  /// Names a track not-sung: it leaves the gap — no re-solve, no requeue
  /// (docs/smart-lyrics.md §1, 除名).
  Future<void> markNotSung(int songId, {String source = 'reader'}) async {
    final database = await _db();
    database.addMarkRow(
      songId: songId,
      kind: SmartLyricsMarkKind.instrumental.id,
      source: source,
      now: _now(),
    );
    await markInstrumental(songId);
  }

  /// Takes back the mark of one line — the reader heard right the second
  /// time.
  Future<void> unmarkLine(int songId, int line) async {
    final database = await _db();
    database.revokeMarkRows(
      songId,
      line: line,
      kind: SmartLyricsMarkKind.line.id,
    );
    database.requeueSongTask(songId, now: _now());
  }

  /// Takes back the whole-track mark; the track is in line again. The
  /// flags on its lines stand — they have their own way out.
  Future<void> unmarkSong(int songId) async {
    final database = await _db();
    database.revokeMarkRows(songId, kind: SmartLyricsMarkKind.song.id);
    database.requeueSongTask(songId, now: _now());
  }

  /// Takes the not-sung name back: the track is a gap again, and in line.
  Future<void> unmarkNotSung(int songId) async {
    final database = await _db();
    database.revokeMarkRows(
      songId,
      kind: SmartLyricsMarkKind.instrumental.id,
    );
    database.requeueSongTask(songId, now: _now());
  }

  /// What the panel shows of a track's open marks.
  Future<SmartLyricsSongFlags> flagsOf(int songId) async {
    final open = await openMarks(songId);
    return SmartLyricsSongFlags(
      lines: {
        for (final mark in open)
          if (mark.kind == SmartLyricsMarkKind.line && mark.line != null)
            mark.line!,
      },
      song: open.any((mark) => mark.kind == SmartLyricsMarkKind.song),
      instrumental: open.any(
        (mark) => mark.kind == SmartLyricsMarkKind.instrumental,
      ),
    );
  }

  /// The open marks of a track, in the order they were made — what the
  /// management lists and the panel flies flags for.
  Future<List<SmartLyricsMark>> openMarks(int songId) async {
    final rows = (await _db()).openMarkRows(songId);
    return [for (final row in rows) _markOf(row)];
  }

  /// The marks across the library, grouped by track: the tracks with
  /// something open first, the answered ones behind — the management page
  /// reads this window (docs/smart-lyrics.md §7.4).
  Future<List<SmartLyricsMarkGroup>> markGroups({int limit = 300}) async {
    final rows = (await _db()).markRowsWithSongs(limit: limit);
    final marks = <int, List<SmartLyricsMark>>{};
    final songs = <int, Song>{};
    for (final row in rows) {
      marks.putIfAbsent(row.mark.songId, () => []).add(_markOf(row.mark));
      songs[row.mark.songId] = row.song;
    }
    final groups = [
      for (final entry in marks.entries)
        SmartLyricsMarkGroup(song: songs[entry.key]!, marks: entry.value),
    ];
    groups.sort((a, b) {
      final byOpen = (b.hasOpen ? 1 : 0).compareTo(a.hasOpen ? 1 : 0);
      return byOpen != 0 ? byOpen : a.song.id.compareTo(b.song.id);
    });
    return groups;
  }

  /// An explicit reword answers one line mark: the reader wrote the words
  /// themselves, and that settles the mark (docs/smart-lyrics.md §7.4).
  Future<void> rewordMark(int songId, int line) async {
    (await _db()).rewordMarkRow(songId, line: line, now: _now());
  }

  SmartLyricsMark _markOf(SmartLyricsMarkRow row) => SmartLyricsMark(
    id: row.id,
    songId: row.songId,
    line: row.line,
    kind: SmartLyricsMarkKind.values.byName(row.kind),
    source: row.source,
    state: SmartLyricsMarkState.values.byName(row.state),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

  static int _now() => DateTime.now().millisecondsSinceEpoch;
}
