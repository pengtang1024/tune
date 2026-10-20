import 'package:dbus/dbus.dart';
import 'package:tune/utils/logger.dart';

/// The bus the player shows itself on.
///
/// The player appears on the bus in two steps: the object goes first, the
/// name comes second. The order matters, because the desktop is always
/// watching the bus. It looks the player up the moment the name shows up, so
/// a name without an object behind it answers with an empty interface, and
/// the desktop never learns the name of the application again.
abstract class MprisBus {
  /// Puts the object that answers on the path of the player on the bus.
  Future<void> publish(DBusObject object);

  /// Takes the name the desktop looks the player up by.
  ///
  /// Returns whether this process is the one that holds the name.
  Future<bool> claim(String name);

  /// Gives the bus back.
  Future<void> close();
}

/// The session bus of the machine.
class SessionMprisBus implements MprisBus {
  DBusClient? _client;

  @override
  Future<void> publish(DBusObject object) async {
    final client = _client ??= DBusClient.session();
    await client.registerObject(object);
  }

  @override
  Future<bool> claim(String name) async {
    final client = _client;
    if (client == null) return false;

    final reply = await client.requestName(
      name,
      flags: {DBusRequestNameFlag.doNotQueue},
    );
    return reply == DBusRequestNameReply.primaryOwner;
  }

  @override
  Future<void> close() async {
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
