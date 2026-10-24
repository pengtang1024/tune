import 'package:tune/data/services/artwork/artwork_cache.dart';
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
  MprisStateMapper(this._tracker, this._artwork);

  final PlaybackTrackTracker _tracker;

  /// The covers that were fetched, so the desktop can be pointed at a file.
  final ArtworkCache _artwork;

  /// The cover of the track that was asked for last.
  ///
  /// The address of the cover is asked of the disk, and the disk is slow
  /// enough to be felt while the clock ticks. The mapper keeps the answer
  /// of the current track instead of asking again on every tick.
  String? _artUrl;
  String? _artUrlKey;

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
  ///
  /// The desktop shows the cover by itself, so it is given a place it can
  /// open without asking the network: the file of the cover that was fetched
  /// before. A track whose cover was never fetched keeps the address of the
  /// picture on the network, because that is all there is to point at.
  ///
  /// The answer is kept for the track it belongs to: the file is asked of
  /// the disk, and the mapper is called on every tick of the clock.
  String? _artUrlOf(Song song) {
    final key = '${song.uri}|${song.artworkUrl}|${song.albumArtPath}';
    if (key == _artUrlKey) return _artUrl;
    _artUrlKey = key;
    _artUrl = _resolveArtUrl(song);
    return _artUrl;
  }

  /// Asks the disk where the cover of the track is.
  String? _resolveArtUrl(Song song) {
    final local = song.albumArtPath;
    if (local != null && local.isNotEmpty) return Uri.file(local).toString();
    final remote = song.artworkUrl;
    if (remote == null || remote.isEmpty) return null;
    final cached = _artwork.coverFileFor(remote);
    if (cached != null) return Uri.file(cached).toString();
    return remote;
  }
}
