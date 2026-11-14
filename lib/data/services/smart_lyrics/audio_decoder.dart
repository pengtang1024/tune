import 'dart:io';

/// Turns a compressed track into the audio the local engines read.
///
/// The desktop has no implementation here: it shells out to the system
/// ffmpeg. Android has no ffmpeg to shell out to, so the platform decoder
/// answers instead (docs/android.md E5). The service only asks whether it
/// has one; the capability table decides.
abstract class AudioDecoder {
  /// Decodes [source] to 16 kHz mono 16-bit PCM WAV inside [folder], or
  /// answers null when the platform cannot decode this file. Null is a
  /// failure to report, never a decoded track.
  Future<File?> decodeToWav(File source, {required Directory folder});
}
