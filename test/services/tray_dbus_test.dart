import 'dart:typed_data';

import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/impl/tray/dbus_menu.dart';
import 'package:tune/data/services/impl/tray/tray_icon_image.dart';
import 'package:tune/data/services/impl/tray/tray_icon_object.dart';
import 'package:tune/data/services/tray/tray_service.dart';
import 'dbus_test_helpers.dart';

void main() {
  group('the menu of the tray icon', () {
    late List<String> clicked;
    late TrayMenuObject menu;

    setUp(() {
      clicked = [];
      menu = TrayMenuObject(DBusObjectPath('/MenuBar'), clicked.add);
      menu.setEntries(const [
        TrayMenuEntry(key: 'playPause', label: 'Play'),
        TrayMenuEntry.separator(),
        TrayMenuEntry(key: 'quit', label: 'Quit', enabled: false),
      ]);
    });

    test('answers with the tree of the entries', () async {
      final response = await menu.handleMethodCall(
        dbusCall('GetLayout', [
          const DBusInt32(0),
          const DBusInt32(-1),
          DBusArray(DBusSignature('s')),
        ]),
      );

      final layout = response.returnValues[1];
      expect(layout, isA<DBusStruct>());
      final children = (layout as DBusStruct).children[2] as DBusArray;
      expect(children.children, hasLength(3));
    });

    test('answers with the properties of the asked entries', () async {
      final response = await menu.handleMethodCall(
        dbusCall('GetGroupProperties', [
          DBusArray(DBusSignature('i'), [const DBusInt32(1)]),
          DBusArray(DBusSignature('s')),
        ]),
      );

      final group = (response.returnValues[0] as DBusArray).children.single;
      final properties = (group as DBusStruct).children[1] as DBusDict;
      expect(dbusProperty(properties, 'label'), const DBusString('Play'));
      expect(dbusProperty(properties, 'type'), const DBusString('standard'));
    });

    test('names a separator a separator', () async {
      final response = await menu.handleMethodCall(
        dbusCall('GetProperty', [
          const DBusInt32(2),
          const DBusString('type'),
        ]),
      );

      final value = (response.returnValues[0] as DBusVariant).value;
      expect(value, const DBusString('separator'));
    });

    test('carries out the action of a clicked entry', () async {
      await menu.handleMethodCall(
        dbusCall('Event', [
          const DBusInt32(1),
          const DBusString('clicked'),
          const DBusVariant(DBusInt32(0)),
          const DBusUint32(0),
        ]),
      );

      expect(clicked, ['playPause']);
    });

    test('leaves a separator alone when it is clicked', () async {
      await menu.handleMethodCall(
        dbusCall('Event', [
          const DBusInt32(2),
          const DBusString('clicked'),
          const DBusVariant(DBusInt32(0)),
          const DBusUint32(0),
        ]),
      );

      expect(clicked, isEmpty);
    });
  });

  group('the icon of the tray', () {
    late TrayIconObject icon;

    setUp(() {
      icon = TrayIconObject(
        DBusObjectPath('/StatusNotifierItem'),
        menuPath: '/MenuBar',
        onActivated: () {},
      );
    });

    test('tells the desktop where the menu is', () async {
      final response = await icon.getAllProperties(TrayIconObject.interfaceName);

      final properties = response.returnValues[0] as DBusDict;
      expect(dbusProperty(properties, 'Menu'), DBusObjectPath('/MenuBar'));
      expect(
        dbusProperty(properties, 'Category'),
        const DBusString('ApplicationStatus'),
      );
      expect(dbusProperty(properties, 'ItemIsMenu'), const DBusBoolean(false));
    });

    test('shows the song in the tip of the mouse', () async {
      icon.setTooltip('Song - Artist');

      final response = await icon.getProperty(
        TrayIconObject.interfaceName,
        'ToolTip',
      );

      final tip = (response.returnValues[0] as DBusVariant).value as DBusStruct;
      expect(tip.children[2], const DBusString('Song - Artist'));
    });

    test('shows the picture in the sizes the panel asks for', () async {
      icon.setIcon([
        TrayIconImage(width: 24, height: 24, argb: Uint8List(24 * 24 * 4)),
      ]);

      final response = await icon.getProperty(
        TrayIconObject.interfaceName,
        'IconPixmap',
      );

      final pictures = (response.returnValues[0] as DBusVariant).value as DBusArray;
      expect(pictures.children, hasLength(1));
      final picture = pictures.children.single as DBusStruct;
      expect(picture.children[0], const DBusInt32(24));
      expect(picture.children[1], const DBusInt32(24));
    });
  });
}
