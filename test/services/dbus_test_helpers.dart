import 'package:dbus/dbus.dart';

/// A call of the desktop to an object of the player.
DBusMethodCall dbusCall(String name, List<DBusValue> values) {
  return DBusMethodCall(
    sender: ':1.1',
    interface: 'com.canonical.dbusmenu',
    name: name,
    values: values,
  );
}

/// One property out of the properties of the desktop.
///
/// The desktop reads the properties as variants, so the value is unwrapped
/// here and the tests can look at the value itself.
DBusValue? dbusProperty(DBusDict properties, String name) {
  final value = properties.children[DBusString(name)];
  if (value is DBusVariant) return value.value;
  return value;
}
