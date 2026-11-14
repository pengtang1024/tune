import 'package:flutter/material.dart';
import 'package:tune/core/config/app_capabilities.dart';
import 'package:tune/core/extension/localizations_extension.dart';

/// The sections of the settings page.
enum SettingsSection {
  overview,
  appearance,
  library,
  playback,
  lyrics,
  localization,
  components,
  discovery,
  desktop,
  permissions,
  sourceHealth,
  about,
}

/// Whether this build has anything to show under [section].
///
/// The desktop group and the update card are drawn from the capability
/// table: on Windows the window works, but the tray, the media controls and
/// the updater are not there yet, so the page leaves them out instead of
/// offering switches that do nothing.
bool settingsSectionSupported(
  SettingsSection section,
  AppCapabilities capabilities,
) {
  return switch (section) {
    SettingsSection.desktop =>
      capabilities.tray ||
          capabilities.systemMediaControls ||
          capabilities.defaultPlayer,
    // Only Android asks for the permissions at runtime.
    SettingsSection.permissions =>
      capabilities.platform == AppPlatform.android,
    _ => true,
  };
}

/// Whether [section] mentions [query].
bool settingsSectionMatches(
  BuildContext context,
  SettingsSection section,
  String query,
) {
  if (query.isEmpty) return true;
  final text =
      '${settingsSectionLabel(context, section)} '
              '${settingsSectionDescription(context, section)} '
              '${settingsSectionKeywords(context, section)}'
          .toLowerCase();
  return text.contains(query);
}

String settingsSectionLabel(
  BuildContext context,
  SettingsSection section,
) => switch (section) {
  SettingsSection.overview => context.loc.settingsOverview,
  SettingsSection.appearance => context.loc.settingsSectionInterface,
  SettingsSection.library => context.loc.libraryTitle,
  SettingsSection.playback => context.loc.settingsSectionPlayback,
  SettingsSection.lyrics => context.loc.settingsSectionSmartLyrics,
  SettingsSection.localization => context.loc.settingsSectionLocalization,
  SettingsSection.components => context.loc.settingsSectionComponents,
  SettingsSection.discovery => context.loc.settingsSectionDiscovery,
  SettingsSection.desktop => context.loc.settingsSectionDesktop,
  SettingsSection.permissions => context.loc.settingsPermissionsTitle,
  SettingsSection.sourceHealth => context.loc.settingsSectionSourceHealth,
  SettingsSection.about => context.loc.about,
};

String settingsSectionDescription(
  BuildContext context,
  SettingsSection section,
) => switch (section) {
  SettingsSection.overview => context.loc.settingsSubtitle,
  SettingsSection.appearance => context.loc.settingsThemeDescription,
  SettingsSection.library => context.loc.settingsLibraryDescription,
  SettingsSection.playback => context.loc.settingsPlaybackDescription,
  SettingsSection.lyrics => context.loc.settingsSmartLyricsDescription,
  SettingsSection.localization => context.loc.settingsLocalizationDescription,
  SettingsSection.components => context.loc.settingsComponentsDescription,
  SettingsSection.discovery => context.loc.settingsDiscoveryDescription,
  SettingsSection.desktop => context.loc.settingsDesktopDescription,
  SettingsSection.permissions => context.loc.settingsPermissionsDescription,
  SettingsSection.sourceHealth =>
    context.loc.settingsSourceHealthDescription,
  SettingsSection.about => context.loc.appTagline,
};

String settingsSectionKeywords(
  BuildContext context,
  SettingsSection section,
) => switch (section) {
  SettingsSection.appearance => context.loc.settingsSearchKeywordsAppearance,
  SettingsSection.library => context.loc.settingsSearchKeywordsLibrary,
  SettingsSection.playback => context.loc.settingsSearchKeywordsPlayback,
  SettingsSection.lyrics => context.loc.settingsSearchKeywordsLyrics,
  SettingsSection.localization =>
    context.loc.settingsSearchKeywordsLocalization,
  SettingsSection.components => context.loc.settingsSearchKeywordsComponents,
  SettingsSection.discovery => context.loc.settingsSearchKeywordsDiscovery,
  SettingsSection.desktop => context.loc.settingsSearchKeywordsDesktop,
  SettingsSection.permissions => context.loc.settingsSearchKeywordsPermissions,
  SettingsSection.sourceHealth =>
    context.loc.settingsSearchKeywordsSourceHealth,
  SettingsSection.overview || SettingsSection.about => '',
};

IconData settingsSectionIcon(SettingsSection section) => switch (section) {
  SettingsSection.overview => Icons.dashboard_customize_rounded,
  SettingsSection.appearance => Icons.palette_outlined,
  SettingsSection.library => Icons.library_music_rounded,
  SettingsSection.playback => Icons.play_circle_outline_rounded,
  SettingsSection.lyrics => Icons.lyrics_outlined,
  SettingsSection.localization => Icons.translate_rounded,
  SettingsSection.components => Icons.extension_outlined,
  SettingsSection.discovery => Icons.explore_rounded,
  SettingsSection.desktop => Icons.desktop_windows_outlined,
  SettingsSection.permissions => Icons.verified_user_outlined,
  SettingsSection.sourceHealth => Icons.monitor_heart_outlined,
  SettingsSection.about => Icons.info_outline_rounded,
};
