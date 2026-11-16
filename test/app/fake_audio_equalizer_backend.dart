import 'package:tune/data/services/audio_equalizer_backend.dart';
import 'package:tune/domain/models/equalizer_settings.dart';

/// Records what the equalizer controller sent to the backend.
class FakeAudioEqualizerBackend implements AudioEqualizerBackend {
  FakeAudioEqualizerBackend({this.isAvailable = true});

  @override
  bool isAvailable;

  /// Every curve that reached [apply], in order.
  final List<EqualizerSettings> applied = <EqualizerSettings>[];

  /// How often the chain was removed.
  int clearCount = 0;

  /// The last curve that reached the backend.
  EqualizerSettings? get last => applied.isEmpty ? null : applied.last;

  @override
  Future<void> apply(EqualizerSettings settings) async {
    applied.add(settings);
  }

  @override
  Future<void> clear() async {
    clearCount++;
  }
}
