import 'package:tune/data/services/mpris/mpris_snapshot.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/desktop/application/playback_track_tracker.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_state.dart';

/// Turns the state of the player into the words the system controls speak.
///
/// The controls live outside of the app, so the state of the player has to be
/// translated into the shape the specification asks for.
class MprisStateMapper {
  MprisStateMapper(this._tracker);

  final PlaybackTrackTracker _tracker;

  /// The state of the player in the words of the media controls.
  MprisSnapshot snapshotFor(PlaybackState state) {
    final song = state.currentSong;
    return MprisSnapshot(
      status: switch (state.status) {
        PlaybackStatus.playing => MprisPlaybackStatus.playing,
        PlaybackStatus.paused => MprisPlaybackStatus.paused,
        _ => MprisPlaybackStatus.stopped,
      },
      track: song == null ? null : _trackFor(song, state),
      position: state.position,
      volume: state.volume,
      rate: state.speed,
      shuffle: state.playMode == PlayMode.shuffle,
      loopStatus: state.playMode == PlayMode.repeatOne
          ? MprisLoopStatus.track
          : MprisLoopStatus.playlist,
      canPlay: state.hasTrack,
      canPause: state.hasTrack,
      canGoNext: state.canGoNext,
      canGoPrevious: state.canGoPrevious,
      canSeek:
          state.hasTrack &&
          state.duration > Duration.zero &&
          !(song?.isLiveStream ?? false),
    );
  }

  /// The track the system media controls show.
  MprisTrack? _trackFor(Song song, PlaybackState state) {
    _tracker.remember(song);
    return MprisTrack(
      id: '${_tracker.number}',
      title: song.title,
      artists: song.artist.isEmpty ? const [] : [song.artist],
      album: song.album,
      artUrl: _artUrlOf(song),
      url: song.playbackUri,
      length: state.duration,
    );
  }

  /// The address of the cover of a track.
  static String? _artUrlOf(Song song) {
    final local = song.albumArtPath;
    if (local != null && local.isNotEmpty) return Uri.file(local).toString();
    final remote = song.artworkUrl;
    if (remote != null && remote.isNotEmpty) return remote;
    return null;
  }
}
