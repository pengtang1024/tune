import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';

/// What a single click on a track in a list means.
///
/// The library, the favourites and the search results are the same kind of
/// thing, so they share one rule: the list either takes the place of the
/// queue, or the track joins the queue and plays right away.
class ListPlayback {
  ListPlayback({required this.playback, required this.replaceQueue});

  /// The player that does the work.
  final PlaybackController playback;

  /// Whether the list takes the place of the queue.
  final bool replaceQueue;

  /// Plays a track the user picked.
  ///
  /// When the queue is replaced, the track is the whole queue. When it is
  /// not, the track joins the queue and plays right away, so the queue grows
  /// instead of turning into a single song.
  Future<void> play(Song song) async {
    if (replaceQueue) {
      await playback.playSong(song);
      return;
    }
    await playback.enqueueAndPlay(song);
  }

  /// Plays a track out of [list].
  ///
  /// When the queue is replaced, the whole list takes its place and the
  /// player starts at [index]. When it is not, only the track joins the
  /// queue.
  Future<void> playFrom(Song song, List<Song> list, int index) async {
    if (replaceQueue) {
      await playback.playQueue(list, startIndex: index);
      return;
    }
    await playback.enqueueAndPlay(song);
  }
}

/// The rule the lists of the app share.
final listPlaybackProvider = Provider<ListPlayback>((ref) {
  return ListPlayback(
    playback: ref.read(playbackControllerProvider.notifier),
    replaceQueue: ref.watch(
      settingsControllerProvider.select((state) => state.replaceQueueOnClick),
    ),
  );
});
