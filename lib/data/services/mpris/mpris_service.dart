import 'package:tune/data/services/mpris/mpris_snapshot.dart';

/// The actions the system media controls can ask the player to perform.
///
/// The controls are an outside caller, so every action is a request: the
/// player decides whether it can be carried out.
abstract class MprisBackend {
  /// Starts or continues the playback.
  Future<void> play();

  /// Pauses the playback.
  Future<void> pause();

  /// Starts the playback when it is paused, pauses it otherwise.
  Future<void> playPause();

  /// Stops the playback.
  Future<void> stop();

  /// Starts the next track of the queue.
  Future<void> next();

  /// Starts the previous track of the queue.
  Future<void> previous();

  /// Moves the playback by [offset], which may be negative.
  Future<void> seek(Duration offset);

  /// Moves the playback to [position] inside the current track.
  Future<void> setPosition(Duration position);

  /// Plays the audio behind [uri].
  Future<void> openUri(Uri uri);

  /// Changes the volume, from 0 to 1.
  Future<void> setVolume(double volume);

  /// Changes the speed of the playback.
  Future<void> setSpeed(double speed);

  /// Switches the random order of the queue on or off.
  Future<void> setShuffle(bool shuffle);

  /// Changes how the queue repeats.
  Future<void> setLoopStatus(MprisLoopStatus status);

  /// Brings the window of the player to the front.
  Future<void> raise();

  /// Ends the player.
  Future<void> quit();
}

/// The bridge between the player and the system media controls.
///
/// The service owns the bus name and the registered object; the player only
/// publishes snapshots and answers the requests that come back.
abstract class MprisService {
  /// Registers the service on the session bus.
  ///
  /// Returns whether the service is running afterwards. A machine without a
  /// session bus is not an error, the player simply has no media controls.
  Future<bool> start(MprisBackend backend);

  /// Publishes the current state of the player.
  Future<void> update(MprisSnapshot snapshot);

  /// Keeps the place the playback reached up to date.
  ///
  /// The desktop polls the position, so the player answers it without
  /// publishing anything: a signal per tick of the clock would flood the
  /// bus.
  void setPosition(Duration position);

  /// Releases the bus name and the registered object.
  Future<void> dispose();
}
