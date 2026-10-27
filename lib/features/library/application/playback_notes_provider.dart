import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/playback_state.dart';

/// Notes every track that starts playing in the library.
///
/// The library uses the note when it has to drop some tracks: a track that
/// played recently is worth more than one nobody touched. The listener sits
/// here instead of inside the player, so the player keeps knowing nothing
/// about the library.
final playbackNotesProvider = Provider<void>((ref) {
  ref.listen(
    playbackControllerProvider.select(
      (state) => (state.status, state.currentSong?.uri),
    ),
    (previous, next) {
      if (next.$1 != PlaybackStatus.playing) return;
      final uri = next.$2;
      if (uri == null || uri.isEmpty) return;
      if (previous != null &&
          previous.$1 == PlaybackStatus.playing &&
          previous.$2 == uri) {
        return;
      }
      ref.read(libraryControllerProvider.notifier).notePlayed(uri);
    },
  );
});
