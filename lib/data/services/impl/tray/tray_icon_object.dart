import 'package:dbus/dbus.dart';
import 'package:tune/data/services/impl/tray/tray_icon_image.dart';
import 'package:tune/data/services/impl/tray/tray_icon_interface.dart';
import 'package:tune/utils/logger.dart';

/// The icon of the player in the panel of the desktop.
///
/// The desktop looks the icon up on the session bus and shows it in its
/// panel; the picture travels with the player, so the icon shows up even
/// when the program was not installed.
class TrayIconObject extends DBusObject {
  TrayIconObject(
    super.path, {
    required this.menuPath,
    required this.onActivated,
  });

  /// The name of the interface the desktop talks to.
  static const interfaceName = trayIconInterfaceName;

  /// The path of the menu that belongs to the icon.
  final String menuPath;

  /// What to do when the user clicks the icon.
  final void Function() onActivated;

  List<TrayIconImage> _icons = const [];
  String _tooltip = 'Tune';

  /// Sets the text the desktop shows when the mouse rests on the icon.
  void setTooltip(String tooltip) {
    if (_tooltip == tooltip) return;
    _tooltip = tooltip;
    _emitChange('ToolTip', _toolTipValue());
  }

  /// Sets the pictures of the icon.
  void setIcon(List<TrayIconImage> icons) {
    _icons = List<TrayIconImage>.unmodifiable(icons);
    _emitChange('IconPixmap', _iconValue());
    _emitSignal('NewIcon');
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'Activate':
      case 'SecondaryActivate':
        onActivated();
        return DBusMethodSuccessResponse();
      case 'ContextMenu':
      case 'Scroll':
        // The desktop draws the menu itself, so there is nothing to do.
        return DBusMethodSuccessResponse();
      default:
        return DBusMethodErrorResponse.unknownMethod();
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

  @override
  List<DBusIntrospectInterface> introspect() {
    return [trayIconInterface()];
  }

  /// All properties of the icon.
  Map<String, DBusValue> _properties() {
    return {
      'Category': const DBusString('ApplicationStatus'),
      'Id': const DBusString('tune'),
      'Title': const DBusString('Tune'),
      'Status': const DBusString('Active'),
      'WindowId': const DBusInt32(0),
      'IconThemePath': const DBusString(''),
      'IconName': const DBusString(''),
      'IconPixmap': _iconValue(),
      'ToolTip': _toolTipValue(),
      'Menu': DBusObjectPath(menuPath),
      'ItemIsMenu': const DBusBoolean(false),
    };
  }

  /// The pictures of the icon.
  DBusValue _iconValue() {
    return DBusArray(
      DBusSignature('(iiay)'),
      _icons.map(
        (icon) => DBusStruct([
          DBusInt32(icon.width),
          DBusInt32(icon.height),
          DBusArray(DBusSignature('y'), icon.argb.map(DBusByte.new)),
        ]),
      ),
    );
  }

  /// The text the desktop shows when the mouse rests on the icon.
  DBusValue _toolTipValue() {
    return DBusStruct([
      const DBusString(''),
      DBusArray(DBusSignature('(iiay)')),
      DBusString(_tooltip),
      const DBusString(''),
    ]);
  }

  /// Tells the desktop that a property changed.
  void _emitChange(String name, DBusValue value) {
    try {
      emitPropertiesChanged(interfaceName, changedProperties: {name: value});
    } catch (error, stackTrace) {
      Log.error('发布托盘图标的变化失败: $error\n$stackTrace');
    }
  }

  /// Tells the desktop that the icon has to be drawn again.
  void _emitSignal(String name) {
    try {
      emitSignal(interfaceName, name);
    } catch (error, stackTrace) {
      Log.error('发布托盘图标的信号失败: $error\n$stackTrace');
    }
  }
}
