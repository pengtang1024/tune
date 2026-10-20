import 'package:dbus/dbus.dart';
import 'package:tune/data/services/impl/mpris/mpris_interfaces.dart';
import 'package:tune/data/services/impl/mpris/mpris_properties.dart';
import 'package:tune/data/services/impl/mpris/mpris_values.dart';
import 'package:tune/data/services/mpris/mpris_service.dart';
import 'package:tune/data/services/mpris/mpris_snapshot.dart';
import 'package:tune/utils/logger.dart';

/// What the object needs from the service that owns it.
abstract class MprisObjectDelegate {
  /// The player behind the controls, if it is ready.
  MprisBackend? get backend;

  /// The state the controls show.
  MprisSnapshot get snapshot;

  /// Applies a volume the user changed in the system controls.
  Future<void> changeVolume(double volume);

  /// Applies a speed the user changed in the system controls.
  Future<void> changeRate(double rate);

  /// Applies the random order the user switched on or off.
  Future<void> changeShuffle(bool shuffle);

  /// Applies the repeat mode the user changed in the system controls.
  Future<void> changeLoopStatus(MprisLoopStatus status);
}

/// The object the system media controls talk to.
///
/// The controls reach the player through two interfaces: the player itself,
/// which can be raised or closed, and the transport, which carries the track
/// and the commands that move it.
class MprisDbusObject extends DBusObject {
  MprisDbusObject(super.path, this._delegate);

  final MprisObjectDelegate _delegate;

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    final backend = _delegate.backend;
    if (backend == null) {
      return DBusMethodErrorResponse.failed('the player is not ready');
    }

    try {
      switch (methodCall.interface) {
        case mprisPlayerInterface:
          return await _handlePlayerCall(methodCall, backend);
        case mprisTransportInterface:
          return await _handleTransportCall(methodCall, backend);
        default:
          return DBusMethodErrorResponse.unknownInterface();
      }
    } catch (error, stackTrace) {
      Log.error('MPRIS 方法 ${methodCall.name} 执行失败: $error\n$stackTrace');
      return DBusMethodErrorResponse.failed('$error');
    }
  }

  /// Handles the calls of the player interface.
  Future<DBusMethodResponse> _handlePlayerCall(
    DBusMethodCall methodCall,
    MprisBackend backend,
  ) async {
    switch (methodCall.name) {
      case 'Raise':
        await backend.raise();
        return DBusMethodSuccessResponse();
      case 'Quit':
        await backend.quit();
        return DBusMethodSuccessResponse();
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  /// Handles the calls of the transport interface.
  Future<DBusMethodResponse> _handleTransportCall(
    DBusMethodCall methodCall,
    MprisBackend backend,
  ) async {
    switch (methodCall.name) {
      case 'Play':
        await backend.play();
        return DBusMethodSuccessResponse();
      case 'Pause':
        await backend.pause();
        return DBusMethodSuccessResponse();
      case 'PlayPause':
        await backend.playPause();
        return DBusMethodSuccessResponse();
      case 'Stop':
        await backend.stop();
        return DBusMethodSuccessResponse();
      case 'Next':
        await backend.next();
        return DBusMethodSuccessResponse();
      case 'Previous':
        await backend.previous();
        return DBusMethodSuccessResponse();
      case 'Seek':
        await backend.seek(_microseconds(methodCall, 0));
        return DBusMethodSuccessResponse();
      case 'SetPosition':
        await backend.setPosition(_microseconds(methodCall, 1));
        return DBusMethodSuccessResponse();
      case 'OpenUri':
        final address = methodCall.values[0].asString();
        await backend.openUri(Uri.parse(address));
        return DBusMethodSuccessResponse();
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  /// Reads a position in microseconds out of the arguments of a call.
  Duration _microseconds(DBusMethodCall methodCall, int index) {
    if (methodCall.values.length <= index) {
      throw DBusMethodErrorResponse.invalidArgs();
    }
    return Duration(microseconds: methodCall.values[index].asInt64());
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    final value = _propertyValue(interface, name);
    if (value == null) {
      return DBusMethodErrorResponse.unknownProperty();
    }
    return DBusGetPropertyResponse(value);
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    return DBusGetAllPropertiesResponse(_propertiesOf(interface));
  }

  @override
  Future<DBusMethodResponse> setProperty(
    String interface,
    String name,
    DBusValue value,
  ) async {
    if (interface != mprisTransportInterface) {
      return DBusMethodErrorResponse.unknownProperty();
    }
    try {
      switch (name) {
        case 'Volume':
          await _delegate.changeVolume(value.asDouble());
          return DBusMethodSuccessResponse();
        case 'Rate':
          await _delegate.changeRate(value.asDouble());
          return DBusMethodSuccessResponse();
        case 'Shuffle':
          await _delegate.changeShuffle(value.asBoolean());
          return DBusMethodSuccessResponse();
        case 'LoopStatus':
          await _delegate.changeLoopStatus(mprisLoopStatusOf(value.asString()));
          return DBusMethodSuccessResponse();
        case 'Position':
          // The specification asks the client to use SetPosition instead.
          return DBusMethodErrorResponse.propertyReadOnly();
        default:
          return DBusMethodErrorResponse.unknownProperty();
      }
    } catch (error, stackTrace) {
      Log.error('MPRIS 属性 $name 写入失败: $error\n$stackTrace');
      return DBusMethodErrorResponse.failed('$error');
    }
  }

  /// The value of one property, or null when the player has no such property.
  DBusValue? _propertyValue(String interface, String name) {
    return _propertiesOf(interface)[name];
  }

  /// All properties of one interface.
  Map<String, DBusValue> _propertiesOf(String interface) {
    switch (interface) {
      case mprisPlayerInterface:
        return mprisPlayerProperties();
      case mprisTransportInterface:
        return mprisTransportProperties(_delegate.snapshot, path.value);
      default:
        return const {};
    }
  }

  @override
  List<DBusIntrospectInterface> introspect() {
    return mprisInterfaces();
  }
}
