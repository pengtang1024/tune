import 'package:tune/data/services/mpris/mpris_service.dart';
import 'package:tune/data/services/mpris/mpris_snapshot.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/play_mode.dart';

/// The actions the system media controls ask for, carried out by the player.
///
/// The controls are an outside caller, so every action goes through the
/// playback controller; the backend never touches the state itself.
class PlaybackMprisBackend implements MprisBackend {
  PlaybackMprisBackend(
    this._playback, {
    required this.onRaise,
    required this.onQuit,
  });

  final PlaybackController _playback;

  /// Brings the window of the player to the front.
  final Future<void> Function() onRaise;

  /// Ends the player.
  final Future<void> Function() onQuit;

  @override
  Future<void> play() async {
    await _playback.resume();
  }

  @override
  Future<void> pause() async {
    await _playback.pause();
  }

  @override
  Future<void> playPause() async {
    await _playback.togglePlayPause();
  }

  @override
  Future<void> stop() async {
    await _playback.stop();
  }

  @override
  Future<void> next() async {
    await _playback.next();
  }

  @override
  Future<void> previous() async {
    await _playback.previous();
  }

  @override
  Future<void> seek(Duration offset) async {
    final state = _playback.snapshot;
    if (!state.hasTrack) return;
    await _playback.seekTo(state.position + offset);
  }

  @override
  Future<void> setPosition(Duration position) async {
    await _playback.seekTo(position);
  }

  @override
  Future<void> openUri(Uri uri) async {
    final song = Song(
      id: 0,
      title: _titleOf(uri),
      uri: uri.toString(),
      streamUrl: uri.toString(),
      dateAdded: DateTime.now().millisecondsSinceEpoch,
    );
    await _playback.playSong(song);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _playback.setVolume(volume);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _playback.setSpeed(speed);
  }

  @override
  Future<void> setShuffle(bool shuffle) async {
    _playback.setPlayMode(shuffle ? PlayMode.shuffle : PlayMode.sequential);
  }

  @override
  Future<void> setLoopStatus(MprisLoopStatus status) async {
    final mode = switch (status) {
      MprisLoopStatus.track => PlayMode.repeatOne,
      MprisLoopStatus.playlist => PlayMode.sequential,
      MprisLoopStatus.none => PlayMode.sequential,
    };
    _playback.setPlayMode(mode);
  }

  @override
  Future<void> raise() async {
    await onRaise();
  }

  @override
  Future<void> quit() async {
    await onQuit();
  }

  /// The name the stream is known by, when it carries no better one.
  static String _titleOf(Uri uri) {
    final segments = uri.pathSegments.where((part) => part.isNotEmpty);
    if (segments.isNotEmpty) return segments.last;
    return uri.host.isEmpty ? uri.toString() : uri.host;
  }
}
