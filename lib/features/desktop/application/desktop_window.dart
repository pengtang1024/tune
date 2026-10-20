import 'package:tune/core/services/window_manager_service.dart';

/// The window of the player on the desktop.
///
/// The window can be hidden while the tray keeps the player alive, so the
/// window is a thing of its own and not a part of the layout.
class DesktopWindow {
  DesktopWindow({required this.closeToTray, required this.hasTray});

  /// Whether closing the window only hides it.
  final bool Function() closeToTray;

  /// Whether the tray is there to keep the player alive.
  final bool Function() hasTray;

  /// Lets the player decide what closing the window means.
  Future<void> takeOverClose() async {
    WindowManagerService.setCloseHandler(_handleClose);
    await WindowManagerService.setPreventClose(true);
  }

  /// Gives closing the window back to the desktop.
  void releaseClose() {
    WindowManagerService.setCloseHandler(null);
  }

  /// Brings the window to the front.
  Future<void> show() async {
    await WindowManagerService.show();
    await WindowManagerService.focus();
  }

  /// Shows the window when it is hidden, hides it when it is there.
  Future<void> toggle() async {
    final visible = await WindowManagerService.isVisible();
    if (visible) {
      await WindowManagerService.hide();
    } else {
      await show();
    }
  }

  /// Ends the player.
  Future<void> quit() async {
    await WindowManagerService.destroy();
  }

  /// Decides what happens when the user closes the window.
  Future<void> _handleClose() async {
    if (closeToTray() && hasTray()) {
      await WindowManagerService.hide();
      return;
    }
    await quit();
  }
}
