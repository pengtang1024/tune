import 'package:dbus/dbus.dart';
import 'package:tune/data/services/impl/dbus_introspection.dart';

/// The name of the interface the desktop talks to.
const dbusMenuInterfaceName = 'com.canonical.dbusmenu';

/// The description of the interface of the menu of the tray icon.
///
/// The desktop reads the description to learn which methods and properties
/// the menu offers before it asks for the entries.
DBusIntrospectInterface dbusMenuInterface() {
  return DBusIntrospectInterface(
    dbusMenuInterfaceName,
    methods: [
      dbusMethod(
        'GetLayout',
        inArgs: [
          ('i', 'parentId'),
          ('i', 'recursionDepth'),
          ('as', 'propertyNames'),
        ],
        outArgs: [('u', 'revision'), ('(ia{sv}av)', 'layout')],
      ),
      dbusMethod(
        'GetGroupProperties',
        inArgs: [('ai', 'ids'), ('as', 'propertyNames')],
        outArgs: [('a(ia{sv})', 'properties')],
      ),
      dbusMethod(
        'GetProperty',
        inArgs: [('i', 'id'), ('s', 'name')],
        outArgs: [('v', 'value')],
      ),
      dbusMethod(
        'Event',
        inArgs: [
          ('i', 'id'),
          ('s', 'eventId'),
          ('v', 'data'),
          ('u', 'timestamp'),
        ],
        outArgs: [('u', 'revision')],
      ),
      dbusMethod(
        'AboutToShow',
        inArgs: [('i', 'id')],
        outArgs: [('b', 'needUpdate')],
      ),
    ],
    properties: [
      dbusProperty('Version', 'u'),
      dbusProperty('TextDirection', 's'),
      dbusProperty('Status', 's'),
      dbusProperty('IconThemePath', 'as'),
    ],
  );
}
