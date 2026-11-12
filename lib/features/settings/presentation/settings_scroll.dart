import 'package:flutter/material.dart';
import 'package:tune/features/settings/presentation/settings_section_catalog.dart';

/// Scrolls the page to [section].
///
/// Returns null when the section has no anchor yet, so the caller can drop
/// its programmatic-scroll flag instead of waiting on a future that never
/// starts.
Future<void>? settingsScrollToSection({
  required ScrollController controller,
  required Map<SettingsSection, GlobalKey> sectionKeys,
  required SettingsSection section,
}) {
  if (section == SettingsSection.overview) {
    return controller.animateTo(
      0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }
  final anchor = sectionKeys[section]?.currentContext;
  if (anchor == null) return null;
  return Scrollable.ensureVisible(
    anchor,
    duration: const Duration(milliseconds: 180),
    alignment: 0.02,
    curve: Curves.easeOut,
  );
}

/// The section under the top of the page, for the rail to follow.
///
/// Returns null when the viewport is not laid out yet.
SettingsSection? settingsSectionAtTop({
  required ScrollController controller,
  required GlobalKey scrollViewKey,
  required Map<SettingsSection, GlobalKey> sectionKeys,
  required bool Function(SettingsSection) visible,
}) {
  if (controller.offset <= 4) return SettingsSection.overview;
  final viewport =
      scrollViewKey.currentContext?.findRenderObject() as RenderBox?;
  if (viewport == null) return null;
  final top = viewport.localToGlobal(Offset.zero).dy;
  SettingsSection? active;
  for (final section in SettingsSection.values) {
    if (!visible(section)) continue;
    final box =
        sectionKeys[section]?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) continue;
    final cardTop = box.localToGlobal(Offset.zero).dy;
    if (cardTop <= top + 24) active = section;
  }
  return active;
}
