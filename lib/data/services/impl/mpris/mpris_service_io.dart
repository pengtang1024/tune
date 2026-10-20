import 'dart:io' show Platform;

import 'package:dbus/dbus.dart';
import 'package:tune/data/services/impl/mpris/mpris_dbus_object.dart';
import 'package:tune/data/services/impl/mpris/mpris_interfaces.dart';
import 'package:tune/data/services/impl/mpris/mpris_values.dart';
import 'package:tune/data/services/mpris/mpris_service.dart';
import 'package:tune/data/services/mpris/mpris_snapshot.dart';
import 'package:tune/utils/logger.dart';

/// The bus name the desktop looks the player up by.
const mprisBusName = 'org.mpris.MediaPlayer2.tune';

/// The object the desktop talks to.
const mprisObjectPath = '/org/mpris/MediaPlayer2';

/// The media controls of the desktop, backed by the session bus.
///
/// The service owns the bus name and answers the calls of the desktop; the
/// player only publishes snapshots and carries the commands out.
class MprisServiceImpl implements MprisService, MprisObjectDelegate {
  MprisServiceImpl();

  DBusClient? _client;
  MprisDbusObject? _object;
  MprisBackend? _backend;
  MprisSnapshot _snapshot = const MprisSnapshot();

  @override
  MprisBackend? get backend => _backend;

  @override
  MprisSnapshot get snapshot => _snapshot;

  @override
  Future<bool> start(MprisBackend backend) async {
    // The media controls are a desktop feature; other platforms keep the
    // player to itself.
    if (!Platform.isLinux) return false;

    _backend = backend;
    try {
      final client = DBusClient.session();
      final reply = await client.requestName(
        mprisBusName,
        flags: {DBusRequestNameFlag.doNotQueue},
      );
      if (reply != DBusRequestNameReply.primaryOwner) {
        // Another player already answers on this name.
        Log.info('系统媒体控制的名字已被占用，放弃注册');
        await client.close();
        return false;
      }

      final object = MprisDbusObject(DBusObjectPath(mprisObjectPath), this);
      await client.registerObject(object);
      _client = client;
      _object = object;
      Log.info('系统媒体控制已注册: $mprisBusName');
      return true;
    } catch (error, stackTrace) {
      Log.error('注册系统媒体控制失败: $error\n$stackTrace');
      await _close();
      return false;
    }
  }

  @override
  Future<void> update(MprisSnapshot snapshot) async {
    final object = _object;
    if (object == null) return;

    final previous = _snapshot;
    _snapshot = snapshot;

    final changed = _changedProperties(previous, snapshot);
    if (changed.isEmpty) return;

    try {
      await object.emitPropertiesChanged(
        mprisTransportInterface,
        changedProperties: changed,
      );
    } catch (error, stackTrace) {
      Log.error('发布系统媒体控制的状态失败: $error\n$stackTrace');
    }
  }

  @override
  Future<void> dispose() async {
    _backend = null;
    _object = null;
    await _close();
  }

  /// The properties that differ between two snapshots.
  ///
  /// The position is left out on purpose: the desktop polls it, and a signal
  /// per playback tick would flood the bus.
  Map<String, DBusValue> _changedProperties(
    MprisSnapshot previous,
    MprisSnapshot next,
  ) {
    final changed = <String, DBusValue>{};
    if (previous.status != next.status) {
      changed['PlaybackStatus'] = DBusString(mprisStatusName(next.status));
    }
    if (previous.track != next.track) {
      changed['Metadata'] = mprisMetadataValue(mprisObjectPath, next.track);
    }
    if (previous.volume != next.volume) {
      changed['Volume'] = DBusDouble(next.volume);
    }
    if (previous.rate != next.rate) {
      changed['Rate'] = DBusDouble(next.rate);
    }
    if (previous.shuffle != next.shuffle) {
      changed['Shuffle'] = DBusBoolean(next.shuffle);
    }
    if (previous.loopStatus != next.loopStatus) {
      changed['LoopStatus'] = DBusString(mprisLoopStatusName(next.loopStatus));
    }
    if (previous.canPlay != next.canPlay) {
      changed['CanPlay'] = DBusBoolean(next.canPlay);
    }
    if (previous.canPause != next.canPause) {
      changed['CanPause'] = DBusBoolean(next.canPause);
    }
    if (previous.canGoNext != next.canGoNext) {
      changed['CanGoNext'] = DBusBoolean(next.canGoNext);
    }
    if (previous.canGoPrevious != next.canGoPrevious) {
      changed['CanGoPrevious'] = DBusBoolean(next.canGoPrevious);
    }
    if (previous.canSeek != next.canSeek) {
      changed['CanSeek'] = DBusBoolean(next.canSeek);
    }
    return changed;
  }

  @override
  Future<void> changeVolume(double volume) async {
    await _backend?.setVolume(volume);
  }

  @override
  Future<void> changeRate(double rate) async {
    await _backend?.setSpeed(rate);
  }

  @override
  Future<void> changeShuffle(bool shuffle) async {
    await _backend?.setShuffle(shuffle);
  }

  @override
  Future<void> changeLoopStatus(MprisLoopStatus status) async {
    await _backend?.setLoopStatus(status);
  }

  /// Closes the connection to the bus.
  Future<void> _close() async {
    final client = _client;
    _client = null;
    if (client == null) return;
    try {
      await client.close();
    } catch (error, stackTrace) {
      Log.error('断开与总线的连接失败: $error\n$stackTrace');
    }
  }
}
