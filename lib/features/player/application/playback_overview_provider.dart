import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/audio_source_status.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_overview.dart';
import 'package:tune/features/player/domain/playback_state.dart';

/// The slow half of the playback, as one value.
///
/// The position moves several times a second. A surface that watches the
/// whole playback state is therefore rebuilt by the position even when it
/// only draws the title of the track — the dock and the now playing page
/// were rebuilt three hundred times over for one tick.
///
/// This provider hands out the slow half alone, so the position only reaches
/// the surfaces that show it.
///
/// The position itself still belongs to the one owner, the playback
/// controller: this is a narrower way of reading it, not a second copy.
final playbackOverviewProvider = Provider<PlaybackOverview>((ref) {
  final fields = ref.watch(playbackControllerProvider.select(_slowFields));

  final uri = fields.currentUri;
  final index = uri == null
      ? -1
      : fields.queue.indexWhere((song) => song.uri == uri);

  return PlaybackOverview(
    status: fields.status,
    currentSong: index < 0 ? null : fields.queue[index],
    currentIndex: index,
    queue: fields.queue,
    playMode: fields.playMode,
    volume: fields.volume,
    errorMessage: fields.errorMessage,
    audioSourceStatus: fields.audioSourceStatus,
  );
});

/// The fields of the playback state that change slowly.
///
/// The position and the duration are left out on purpose: they are the fast
/// half, and the surfaces that show them ask for them on their own.
typedef _SlowFields = ({
  PlaybackStatus status,
  List<Song> queue,
  String? currentUri,
  PlayMode playMode,
  double volume,
  String? errorMessage,
  AudioSourceStatus audioSourceStatus,
});

_SlowFields _slowFields(PlaybackState state) {
  return (
    status: state.status,
    queue: state.queue,
    currentUri: state.currentUri,
    playMode: state.playMode,
    volume: state.volume,
    errorMessage: state.errorMessage,
    audioSourceStatus: state.audioSourceStatus,
  );
}
