import 'package:dbus/dbus.dart';
import 'package:tune/data/services/impl/dbus_introspection.dart';

/// The name of the interface the desktop talks to.
const trayIconInterfaceName = 'org.kde.StatusNotifierItem';

/// The description of the interface of the icon in the panel.
///
/// The desktop reads the description to learn which methods, signals and
/// properties the icon offers.
DBusIntrospectInterface trayIconInterface() {
  return DBusIntrospectInterface(
    trayIconInterfaceName,
    methods: [
      dbusMethod('Activate', inArgs: [('i', 'x'), ('i', 'y')]),
      dbusMethod('SecondaryActivate', inArgs: [('i', 'x'), ('i', 'y')]),
      dbusMethod('ContextMenu', inArgs: [('i', 'x'), ('i', 'y')]),
      dbusMethod('Scroll', inArgs: [('i', 'delta'), ('s', 'orientation')]),
    ],
    signals: [
      dbusSignal('NewIcon'),
      dbusSignal('NewTitle'),
      dbusSignal('NewStatus'),
    ],
    properties: [
      dbusProperty('Category', 's'),
      dbusProperty('Id', 's'),
      dbusProperty('Title', 's'),
      dbusProperty('Status', 's'),
      dbusProperty('WindowId', 'i'),
      dbusProperty('IconThemePath', 's'),
      dbusProperty('IconName', 's'),
      dbusProperty('IconPixmap', 'a(iiay)'),
      dbusProperty('ToolTip', '(sa(iiay)ss)'),
      dbusProperty('Menu', 'o'),
      dbusProperty('ItemIsMenu', 'b'),
    ],
  );
}
