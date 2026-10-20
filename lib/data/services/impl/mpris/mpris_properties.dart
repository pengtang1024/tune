import 'package:dbus/dbus.dart';
import 'package:tune/data/services/desktop/audio_mime_types.dart';
import 'package:tune/data/services/impl/mpris/mpris_values.dart';
import 'package:tune/data/services/mpris/mpris_snapshot.dart';

/// The properties of the player interface.
///
/// They describe the player itself, so they do not change while a track plays.
Map<String, DBusValue> mprisPlayerProperties() {
  return {
    'CanQuit': const DBusBoolean(true),
    'CanRaise': const DBusBoolean(true),
    'HasTrackList': const DBusBoolean(false),
    'Identity': const DBusString('Tune'),
    'DesktopEntry': const DBusString('cn.iouf.tune'),
    'SupportedUriSchemes': DBusArray(DBusSignature('s'), const [
      DBusString('file'),
      DBusString('http'),
      DBusString('https'),
    ]),
    'SupportedMimeTypes': DBusArray(
      DBusSignature('s'),
      supportedAudioMimeTypes.map(DBusString.new),
    ),
  };
}

/// The properties of the transport interface, for the given state.
Map<String, DBusValue> mprisTransportProperties(
  MprisSnapshot snapshot,
  String objectPath,
) {
  return {
    'PlaybackStatus': DBusString(mprisStatusName(snapshot.status)),
    'Metadata': mprisMetadataValue(objectPath, snapshot.track),
    'Position': DBusInt64(snapshot.position.inMicroseconds),
    'Volume': DBusDouble(snapshot.volume),
    'Rate': DBusDouble(snapshot.rate),
    'Shuffle': DBusBoolean(snapshot.shuffle),
    'LoopStatus': DBusString(mprisLoopStatusName(snapshot.loopStatus)),
    'CanPlay': DBusBoolean(snapshot.canPlay),
    'CanPause': DBusBoolean(snapshot.canPause),
    'CanGoNext': DBusBoolean(snapshot.canGoNext),
    'CanGoPrevious': DBusBoolean(snapshot.canGoPrevious),
    'CanSeek': DBusBoolean(snapshot.canSeek),
    'MinimumRate': const DBusDouble(0.5),
    'MaximumRate': const DBusDouble(2),
  };
}
