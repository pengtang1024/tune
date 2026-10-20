import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/player/application/list_playback.dart';
import 'package:tune/features/settings/application/settings_controller.dart';

/// What a double click on a track in a list means.
///
/// A double click marks the track as a favorite. It plays the track as well
/// when the user asked for that; otherwise the music keeps playing and only
/// the heart changes.
class ListDoubleClick {
  ListDoubleClick({
    required this.favorites,
    required this.playback,
    required this.playsToo,
  });

  /// The controller that knows which tracks are liked.
  final FavoritesController favorites;

  /// The rule a single click follows.
  final ListPlayback playback;

  /// Whether a double click plays the track as well.
  final bool playsToo;

  /// Marks the track as a favorite, and plays it when that is the rule.
  Future<void> like(Song song) async {
    await favorites.toggle(song.uri);
    if (playsToo) {
      await playback.play(song);
    }
  }
}

/// The rule the lists of the app share.
final listDoubleClickProvider = Provider<ListDoubleClick>((ref) {
  return ListDoubleClick(
    favorites: ref.read(favoritesControllerProvider.notifier),
    playback: ref.watch(listPlaybackProvider),
    playsToo: ref.watch(
      settingsControllerProvider.select((state) => state.playOnDoubleClick),
    ),
  );
});
