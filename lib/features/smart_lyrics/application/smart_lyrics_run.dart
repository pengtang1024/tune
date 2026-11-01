/// The run holds no lyrics of its own: the sheet that comes out of it goes
/// through [LyricsController] into [LyricsState], and the file next to the
/// audio. This state is only the progress the panel shows while the words
/// are not there yet.
library;

import 'package:tune/data/services/smart_lyrics/smart_lyrics_service.dart';

/// How the run of the smart pipeline stands, while it stands
/// (docs/smart-lyrics.md §7.1).
enum SmartLyricsPhase { idle, running, done, failed }

class SmartLyricsRun {
  final SmartLyricsPhase phase;

  /// The track the run works on; the panel shows the progress only for the
  /// track that plays.
  final int? songId;

  /// Why a failed run failed, as the panel names it.
  final SmartLyricsFailure? failure;

  const SmartLyricsRun({
    this.phase = SmartLyricsPhase.idle,
    this.songId,
    this.failure,
  });

  /// Whether a run is on its way for [song].
  bool isRunningFor(int? songId) =>
      phase == SmartLyricsPhase.running && this.songId == songId;
}
