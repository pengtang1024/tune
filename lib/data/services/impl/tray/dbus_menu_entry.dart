import 'package:dbus/dbus.dart';
import 'package:tune/data/services/tray/tray_service.dart';

/// The properties of one entry of the menu, in the shape the desktop expects.
///
/// An empty list of names asks for all of them, which is what the desktop
/// does when it reads the entries of the menu.
Map<String, DBusValue> dbusMenuEntryProperties(
  TrayMenuEntry entry,
  List<String> names,
) {
  final all = <String, DBusValue>{
    'visible': const DBusBoolean(true),
    'enabled': DBusBoolean(entry.enabled),
    'label': DBusString(entry.label),
    'type': DBusString(entry.isSeparator ? 'separator' : 'standard'),
  };

  if (names.isEmpty) return all;
  return {
    for (final name in names)
      if (all.containsKey(name)) name: all[name]!,
  };
}
