import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One run of the pipeline at a time (M12).
///
/// The panel button and the batch both run through the same service
/// instance — the same engine objects, the same whisper workspace, the
/// same `whisper-out` prefix. Two overlapping runs would corrupt each
/// other's sheet or record a bogus failure. The claim happens before the
/// first `await`, so two quick presses cannot both win the gap the old
/// `state.running` check left open.
class SmartLyricsRunLock {
  var _panel = false;
  var _batch = false;

  bool get panelRunning => _panel;
  bool get batchRunning => _batch;
  bool get busy => _panel || _batch;

  /// Takes the panel seat; `false` when the batch holds it.
  bool claimPanel() {
    if (busy) return false;
    _panel = true;
    return true;
  }

  void releasePanel() => _panel = false;

  /// Takes the batch seat; `false` when the panel or another batch holds it.
  bool claimBatch() {
    if (busy) return false;
    _batch = true;
    return true;
  }

  void releaseBatch() => _batch = false;
}

/// The lock every pipeline door reads.
final smartLyricsRunLockProvider = Provider<SmartLyricsRunLock>(
  (ref) => SmartLyricsRunLock(),
);
