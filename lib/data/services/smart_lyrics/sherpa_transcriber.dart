import 'dart:io';

import 'package:tune/data/services/smart_lyrics/sherpa_transcript.dart';

/// One way of asking a sherpa model what a piece of audio says.
///
/// The engine owns the pieces, the clock and the lines; the transcriber only
/// answers for one 16 kHz mono WAV. The desktop answers by running a binary
/// in a child process (`sherpa_process_transcriber.dart`), a phone answers
/// in-process through `sherpa_onnx` (`sherpa_ffi_transcriber.dart`) because
/// it may not execute an external binary (docs/android.md E5). Keeping the
/// two behind this seam is what lets the engine stay platform-free.
abstract class SherpaTranscriber {
  /// Clears a previous cancel so the next song can use the channel again.
  void reset();

  /// The words of one piece, on the piece's own clock.
  Future<SherpaAnswer> listen(File wav);

  /// Stops the run; a cancelled run answers with an error, never with words.
  void cancel();

  bool get cancelled;

  /// Releases whatever the backend holds (a native recognizer, a process).
  Future<void> dispose();
}
