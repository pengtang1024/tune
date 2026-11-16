import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/equalizer_settings.dart';
import 'package:tune/features/player/application/equalizer_controller.dart';
import 'package:tune/providers/persistence_providers.dart';

/// The equalizer settings and the only writer of them.
final equalizerControllerProvider =
    StateNotifierProvider<EqualizerController, EqualizerSettings>((ref) {
      final backend = ref.watch(audioPlayerServiceProvider).equalizer;
      return EqualizerController(
        ref.watch(persistenceServiceProvider),
        backend,
      );
    });

/// Whether the backend of this platform offers an equalizer.
///
/// Read by the places that open the panel: an entry that leads to a switch
/// that cannot change the sound is worse than no entry.
final equalizerAvailableProvider = Provider<bool>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.equalizer?.isAvailable ?? false;
});
