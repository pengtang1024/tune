/// The batch of the smart lyrics pipeline (docs/smart-lyrics.md §7.2, M5):
/// what one track's task stands at, and how the run as a whole stands.
library;

/// What the task of a track stands at.
///
/// The rows only exist for tracks the three segments could not bring words
/// for; a track that already carries lyrics is never a task.
enum SmartLyricsTaskStatus {
  /// Waiting for its turn.
  pending,

  /// A run is on it right now.
  running,

  /// The pool agreed; the sheet sits next to the audio.
  done,

  /// The pool ran, but lines were left in dispute.
  disputed,

  /// The pool heard no voice; the track is not a gap.
  instrumental,

  /// The run failed; the track waits for a retry, never a re-run by itself.
  failed,

  /// The reader or the batch chose to leave this one out.
  skipped;

  /// The name the tables store.
  String get id => name;
}

/// How a batch run stands while it stands.
class SmartLyricsBatchProgress {
  final bool running;

  /// The track the run is on right now, while one is.
  final int? currentSongId;

  /// The tasks the store holds by their status, for the card.
  final Map<SmartLyricsTaskStatus, int> counts;

  /// The cloud votes the run spent, against the budget it was given.
  final int cloudUsed;

  /// The budget the reader set; `null` when they let the run go unlimited.
  final int? cloudBudget;

  /// How far the current song's transcription has come, 0..1; `null`
  /// between songs. The card draws a bar with it so a long podcast does
  /// not look like a hung process.
  final double? progress;

  const SmartLyricsBatchProgress({
    required this.running,
    this.currentSongId,
    this.counts = const {},
    this.cloudUsed = 0,
    this.cloudBudget,
    this.progress,
  });

  /// The account before any run started.
  static const SmartLyricsBatchProgress idle = SmartLyricsBatchProgress(
    running: false,
  );

  int countOf(SmartLyricsTaskStatus status) => counts[status] ?? 0;

  /// The tasks that are left to run.
  int get pending => countOf(SmartLyricsTaskStatus.pending);

  /// The tasks that ended without a sheet.
  int get failed => countOf(SmartLyricsTaskStatus.failed);

  /// Whether the last run stopped because its cloud budget was spent.
  ///
  /// A run that stopped this way is not an error: the tracks stay pending
  /// and the next run picks them up.
  bool get pausedForBudget =>
      !running && cloudBudget != null && cloudUsed >= cloudBudget!;
}
