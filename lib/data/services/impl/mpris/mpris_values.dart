import 'package:dbus/dbus.dart';
import 'package:tune/data/services/mpris/mpris_snapshot.dart';

/// The name of a playback state in the wording of the specification.
String mprisStatusName(MprisPlaybackStatus status) {
  return switch (status) {
    MprisPlaybackStatus.playing => 'Playing',
    MprisPlaybackStatus.paused => 'Paused',
    MprisPlaybackStatus.stopped => 'Stopped',
  };
}

/// The name of a repeat mode in the wording of the specification.
String mprisLoopStatusName(MprisLoopStatus status) {
  return switch (status) {
    MprisLoopStatus.none => 'None',
    MprisLoopStatus.track => 'Track',
    MprisLoopStatus.playlist => 'Playlist',
  };
}

/// The repeat mode a name stands for.
MprisLoopStatus mprisLoopStatusOf(String name) {
  return switch (name) {
    'Track' => MprisLoopStatus.track,
    'Playlist' => MprisLoopStatus.playlist,
    _ => MprisLoopStatus.none,
  };
}

/// The metadata of a track in the shape the specification asks for.
///
/// The track identifier has to be an object path, so it is placed below the
/// object the controls talk to.
DBusValue mprisMetadataValue(String objectPath, MprisTrack? track) {
  if (track == null) {
    return DBusDict.stringVariant(const {});
  }
  return DBusDict.stringVariant({
    'mpris:trackid': DBusObjectPath('$objectPath/Track/${track.id}'),
    'mpris:length': DBusInt64(track.length.inMicroseconds),
    'xesam:title': DBusString(track.title),
    'xesam:artist': DBusArray(
      DBusSignature('s'),
      track.artists.map(DBusString.new),
    ),
    'xesam:album': DBusString(track.album),
    if (track.artUrl != null) 'mpris:artUrl': DBusString(track.artUrl!),
    if (track.url != null) 'xesam:url': DBusString(track.url!),
  });
}
