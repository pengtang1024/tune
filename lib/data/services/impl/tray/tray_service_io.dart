import 'dart:io' show Platform, pid;

import 'package:dbus/dbus.dart';
import 'package:tune/data/services/impl/tray/dbus_menu.dart';
import 'package:tune/data/services/impl/tray/tray_icon_image.dart';
import 'package:tune/data/services/impl/tray/tray_icon_object.dart';
import 'package:tune/data/services/tray/tray_service.dart';
import 'package:tune/utils/logger.dart';

/// The path the icon of the player lives at.
const _iconPath = '/StatusNotifierItem';

/// The path the menu of the icon lives at.
const _menuPath = '/MenuBar';

/// The name of the watcher that collects the icons of the panel.
const _watcherName = 'org.kde.StatusNotifierWatcher';

/// The path of the watcher that collects the icons of the panel.
const _watcherPath = '/StatusNotifierWatcher';

/// The method the watcher of the panel listens for.
///
/// The name belongs to the protocol of the panel, so it is the same in every
/// language.
const _registerMethod = 'RegisterStatusNotifierItem';

/// The system tray of the desktop.
///
/// The icon lives in the panel of the desktop and speaks the status notifier
/// protocol, so it works the same on every desktop that follows it.
class TrayServiceImpl implements TrayService {
  DBusClient? _client;
  TrayIconObject? _icon;
  TrayMenuObject? _menu;

  @override
  bool get isSupported => Platform.isLinux;

  @override
  Future<bool> create({
    required String iconPath,
    required String tooltip,
    required List<TrayMenuEntry> menu,
    required void Function(String key) onMenuItemClick,
    required void Function() onClick,
  }) async {
    if (!isSupported) return false;

    try {
      final client = DBusClient.session();
      final busName = _busName();
      final reply = await client.requestName(
        busName,
        flags: {DBusRequestNameFlag.doNotQueue},
      );
      if (reply != DBusRequestNameReply.primaryOwner) {
        // Another icon already answers on this name.
        Log.info('托盘图标的总线名已被占用，放弃注册');
        await client.close();
        return false;
      }

      final menuObject = TrayMenuObject(
        DBusObjectPath(_menuPath),
        onMenuItemClick,
      );
      menuObject.setEntries(menu);
      await client.registerObject(menuObject);

      final iconObject = TrayIconObject(
        DBusObjectPath(_iconPath),
        menuPath: _menuPath,
        onActivated: onClick,
      );
      await client.registerObject(iconObject);
      iconObject.setIcon(await TrayIconImage.loadAll(iconPath));
      iconObject.setTooltip(tooltip);

      _client = client;
      _icon = iconObject;
      _menu = menuObject;

      if (!await _announceToWatcher(client, busName)) {
        await destroy();
        return false;
      }

      Log.info('系统托盘图标已注册: $busName');
      return true;
    } catch (error, stackTrace) {
      Log.error('创建系统托盘图标失败: $error\n$stackTrace');
      await destroy();
      return false;
    }
  }

  @override
  Future<void> setTooltip(String tooltip) async {
    _icon?.setTooltip(tooltip);
  }

  @override
  Future<void> setMenu(List<TrayMenuEntry> menu) async {
    _menu?.setEntries(menu);
  }

  @override
  Future<void> destroy() async {
    final client = _client;
    _client = null;
    _icon = null;
    _menu = null;
    if (client == null) return;

    try {
      await client.close();
    } catch (error, stackTrace) {
      Log.error('断开与总线的连接失败: $error\n$stackTrace');
    }
  }

  /// The name the icon answers to on the bus.
  ///
  /// Every player needs a name of its own, so the number of the process is
  /// part of it.
  static String _busName() => 'org.kde.StatusNotifierItem-$pid-1';

  /// Tells the watcher of the panel about the icon.
  ///
  /// The watchers do not agree on how the icon is announced: the one of GNOME
  /// expects the path of the object and takes the name of the sender, the one
  /// of KDE expects the name of the service and the path of the object. Both
  /// ways are tried, the one that works first wins.
  Future<bool> _announceToWatcher(DBusClient client, String busName) async {
    try {
      await client.callMethod(
        destination: _watcherName,
        path: DBusObjectPath(_watcherPath),
        interface: _watcherName,
        name: _registerMethod,
        values: [const DBusString(_iconPath)],
      );
      return true;
    } catch (error) {
      Log.info('托盘监视器不接受路径形式，改用服务名形式');
    }

    try {
      await client.callMethod(
        destination: _watcherName,
        path: DBusObjectPath(_watcherPath),
        interface: _watcherName,
        name: _registerMethod,
        values: [DBusString(busName), const DBusString(_iconPath)],
      );
      return true;
    } catch (error, stackTrace) {
      Log.error('向托盘监视器注册图标失败: $error\n$stackTrace');
      return false;
    }
  }
}
