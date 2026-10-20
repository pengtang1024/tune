import 'package:dbus/dbus.dart';
import 'package:tune/data/services/impl/tray/dbus_menu_entry.dart';
import 'package:tune/data/services/impl/tray/dbus_menu_interface.dart';
import 'package:tune/data/services/tray/tray_service.dart';
import 'package:tune/utils/logger.dart';

/// The menu of the tray icon, in the shape the desktop expects.
///
/// The desktop asks for the layout of the menu and for the properties of the
/// entries, and it reports a click back through an event.
class TrayMenuObject extends DBusObject {
  TrayMenuObject(super.path, this._onItemClicked);

  /// The name of the interface the desktop talks to.
  static const interfaceName = dbusMenuInterfaceName;

  final void Function(String key) _onItemClicked;

  List<TrayMenuEntry> _entries = const [];

  /// Replaces the entries of the menu.
  void setEntries(List<TrayMenuEntry> entries) {
    _entries = List<TrayMenuEntry>.unmodifiable(entries);
  }

  @override
  List<DBusIntrospectInterface> introspect() {
    return [dbusMenuInterface()];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    try {
      switch (methodCall.name) {
        case 'GetLayout':
          return _getLayout(methodCall);
        case 'GetGroupProperties':
          return _getGroupProperties(methodCall);
        case 'GetProperty':
          return _getProperty(methodCall);
        case 'Event':
          return _handleEvent(methodCall);
        case 'AboutToShow':
          return DBusMethodSuccessResponse([const DBusBoolean(false)]);
        case 'AboutToShowGroup':
          return DBusMethodSuccessResponse([
            DBusArray(DBusSignature('i')),
            DBusArray(DBusSignature('i')),
          ]);
        default:
          return DBusMethodErrorResponse.unknownMethod();
      }
    } catch (error, stackTrace) {
      Log.error('托盘菜单的调用 ${methodCall.name} 失败: $error\n$stackTrace');
      return DBusMethodErrorResponse.failed('$error');
    }
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface != interfaceName) {
      return DBusMethodErrorResponse.unknownProperty();
    }
    final value = _properties()[name];
    if (value == null) {
      return DBusMethodErrorResponse.unknownProperty();
    }
    return DBusGetPropertyResponse(value);
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    if (interface != interfaceName) {
      return DBusGetAllPropertiesResponse(const {});
    }
    return DBusGetAllPropertiesResponse(_properties());
  }

  /// The properties of the menu itself.
  Map<String, DBusValue> _properties() {
    return {
      'Version': const DBusUint32(3),
      'TextDirection': const DBusString('ltr'),
      'Status': const DBusString('normal'),
      'IconThemePath': DBusArray(DBusSignature('s')),
    };
  }

  /// Answers with the tree of the menu.
  ///
  /// The tree is a structure of `(id, properties, children)`, the children
  /// being structures of the same shape.
  DBusMethodResponse _getLayout(DBusMethodCall call) {
    final names = _stringList(call.values[2]);
    final children = <DBusValue>[];
    for (var index = 0; index < _entries.length; index++) {
      final entry = _entries[index];
      children.add(
        DBusVariant(
          DBusStruct([
            DBusInt32(index + 1),
            DBusDict.stringVariant(dbusMenuEntryProperties(entry, names)),
            DBusArray(DBusSignature('v')),
          ]),
        ),
      );
    }

    final root = DBusStruct([
      const DBusInt32(0),
      DBusDict.stringVariant(const {}),
      DBusArray(DBusSignature('v'), children),
    ]);
    return DBusMethodSuccessResponse([const DBusUint32(0), root]);
  }

  /// Answers with the properties of the entries the desktop asked for.
  DBusMethodResponse _getGroupProperties(DBusMethodCall call) {
    final ids = _intList(call.values[0]);
    final names = _stringList(call.values[1]);

    final properties = <DBusValue>[];
    for (final id in ids) {
      final entry = _entryOf(id);
      if (entry == null) continue;
      properties.add(
        DBusStruct([
          DBusInt32(id),
          DBusDict.stringVariant(dbusMenuEntryProperties(entry, names)),
        ]),
      );
    }
    return DBusMethodSuccessResponse([
      DBusArray(DBusSignature('(ia{sv})'), properties),
    ]);
  }

  /// Answers with one property of one entry.
  DBusMethodResponse _getProperty(DBusMethodCall call) {
    final id = call.values[0].asInt32();
    final name = call.values[1].asString();
    final entry = _entryOf(id);
    if (entry == null) {
      return DBusMethodErrorResponse.unknownProperty();
    }
    final value = dbusMenuEntryProperties(entry, const [])[name];
    if (value == null) {
      return DBusMethodErrorResponse.unknownProperty();
    }
    return DBusMethodSuccessResponse([DBusVariant(value)]);
  }

  /// Carries out the action of a clicked entry.
  DBusMethodResponse _handleEvent(DBusMethodCall call) {
    final id = call.values[0].asInt32();
    final event = call.values[1].asString();
    if (event == 'clicked') {
      final entry = _entryOf(id);
      if (entry != null && !entry.isSeparator) {
        _onItemClicked(entry.key);
      }
    }
    return DBusMethodSuccessResponse([const DBusUint32(0)]);
  }

  /// The entry with the given number.
  ///
  /// The numbers start at one; zero is the menu itself.
  TrayMenuEntry? _entryOf(int id) {
    if (id < 1 || id > _entries.length) return null;
    return _entries[id - 1];
  }

  /// The names of the properties the desktop asked for.
  List<String> _stringList(DBusValue value) {
    return value.asStringArray().toList();
  }

  /// The numbers of the entries the desktop asked for.
  List<int> _intList(DBusValue value) {
    return value.asArray().map((item) => item.asInt32()).toList();
  }
}
