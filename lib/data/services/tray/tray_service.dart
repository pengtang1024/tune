/// One entry of the tray menu.
///
/// The key is what the player answers to when the entry is picked; the label
/// is what the user reads.
class TrayMenuEntry {
  const TrayMenuEntry({
    required this.key,
    required this.label,
    this.enabled = true,
  });

  /// A line that only separates the entries above from the ones below.
  const TrayMenuEntry.separator()
    : key = '',
      label = '',
      enabled = false;

  /// The name of the action behind the entry.
  final String key;

  /// The text the user reads.
  final String label;

  /// Whether the entry can be picked.
  final bool enabled;

  /// Whether the entry only separates other entries.
  bool get isSeparator => key.isEmpty;
}

/// The system tray of the desktop.
///
/// The tray keeps the player alive while the window is gone, so it is the
/// place the user comes back to.
abstract class TrayService {
  /// Whether the desktop has a tray the player can use.
  bool get isSupported;

  /// Creates the icon with its menu.
  ///
  /// [onMenuItemClick] is called with the key of the picked entry,
  /// [onClick] is called when the icon itself is clicked.
  Future<bool> create({
    required String iconPath,
    required String tooltip,
    required List<TrayMenuEntry> menu,
    required void Function(String key) onMenuItemClick,
    required void Function() onClick,
  });

  /// Shows a text in the tooltip of the icon.
  Future<void> setTooltip(String tooltip);

  /// Replaces the menu of the icon.
  Future<void> setMenu(List<TrayMenuEntry> menu);

  /// Removes the icon.
  Future<void> destroy();
}
