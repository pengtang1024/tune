import 'package:tune/domain/models/equalizer_settings.dart';

/// What a playback backend has to offer to carry an equalizer.
///
/// Only the backends that can reach a filter graph implement this; the audio
/// service exposes the one it has, and the panel stays hidden when there is
/// none. That keeps the interface honest for the backends that cannot do it
/// (just_audio on mobile) instead of pretending and silently doing nothing.
abstract class AudioEqualizerBackend {
  /// Whether the backend probed the filter graph and can use it.
  ///
  /// The probe runs once during startup: a libmpv build without the ffmpeg
  /// filters answers with an error, and the panel never offers a switch that
  /// changes nothing.
  bool get isAvailable;

  /// Sends the curve to the backend. A disabled or flat curve clears it.
  Future<void> apply(EqualizerSettings settings);

  /// Removes the filter graph, leaving the sound untouched.
  Future<void> clear();
}
