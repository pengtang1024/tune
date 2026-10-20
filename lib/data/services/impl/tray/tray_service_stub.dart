import 'package:tune/data/services/tray/tray_service.dart';

/// The system tray of a platform that has none.
///
/// The player keeps working without an icon in the panel; the window is then
/// the only way back to it.
class TrayServiceImpl implements TrayService {
  @override
  bool get isSupported => false;

  @override
  Future<bool> create({
    required String iconPath,
    required String tooltip,
    required List<TrayMenuEntry> menu,
    required void Function(String key) onMenuItemClick,
    required void Function() onClick,
  }) async => false;

  @override
  Future<void> setTooltip(String tooltip) async {}

  @override
  Future<void> setMenu(List<TrayMenuEntry> menu) async {}

  @override
  Future<void> destroy() async {}
}
