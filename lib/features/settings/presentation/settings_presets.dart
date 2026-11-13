import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/domain/settings_state.dart';
import 'package:tune/features/settings/presentation/settings_section_catalog.dart';

/// One of the choices above a settings card.
class SettingsPreset {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback apply;

  const SettingsPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.apply,
  });
}

/// The presets of [section], empty when the section has none.
List<SettingsPreset> settingsPresetsFor({
  required BuildContext context,
  required SettingsSection section,
  required SettingsState settings,
  required SettingsController controller,
}) {
  switch (section) {
    case SettingsSection.appearance:
      return [
        SettingsPreset(
          id: ThemeMode.system.name,
          title: context.loc.systemMode,
          description: context.loc.settingsThemeDescription,
          icon: Icons.brightness_auto_rounded,
          apply: () => controller.setThemeMode(ThemeMode.system),
        ),
        SettingsPreset(
          id: ThemeMode.light.name,
          title: context.loc.lightMode,
          description: context.loc.settingsThemeDescription,
          icon: Icons.light_mode_rounded,
          apply: () => controller.setThemeMode(ThemeMode.light),
        ),
        SettingsPreset(
          id: ThemeMode.dark.name,
          title: context.loc.darkMode,
          description: context.loc.settingsThemeDescription,
          icon: Icons.dark_mode_rounded,
          apply: () => controller.setThemeMode(ThemeMode.dark),
        ),
      ];
    case SettingsSection.library:
      return [
        SettingsPreset(
          id: 'auto',
          title: context.loc.settingsPresetAutoScan,
          description: context.loc.settingsPresetAutoScanHint,
          icon: Icons.autorenew_rounded,
          apply: () => controller.setAutoScanOnStartup(true),
        ),
        SettingsPreset(
          id: 'manual',
          title: context.loc.settingsPresetManualScan,
          description: context.loc.settingsPresetManualScanHint,
          icon: Icons.touch_app_rounded,
          apply: () => controller.setAutoScanOnStartup(false),
        ),
      ];
    case SettingsSection.playback:
      return [
        SettingsPreset(
          id: 'queue',
          title: context.loc.settingsPresetQueueFirst,
          description: context.loc.settingsPresetQueueFirstHint,
          icon: Icons.queue_music_rounded,
          apply: () => _applyPlayback(
            controller,
            replaceQueue: false,
            favoritesDoubleClick: true,
            onlyLike: false,
          ),
        ),
        SettingsPreset(
          id: 'single',
          title: context.loc.settingsPresetSingleFirst,
          description: context.loc.settingsPresetSingleFirstHint,
          icon: Icons.play_circle_outline_rounded,
          apply: () => _applyPlayback(
            controller,
            replaceQueue: true,
            favoritesDoubleClick: true,
            onlyLike: false,
          ),
        ),
        SettingsPreset(
          id: 'favorite',
          title: context.loc.settingsPresetFavoriteFirst,
          description: context.loc.settingsPresetFavoriteFirstHint,
          icon: Icons.favorite_border_rounded,
          apply: () => _applyPlayback(
            controller,
            replaceQueue: false,
            favoritesDoubleClick: false,
            onlyLike: true,
          ),
        ),
      ];
    case SettingsSection.lyrics:
      return [
        SettingsPreset(
          id: 'manual',
          title: context.loc.settingsPresetLyricsManual,
          description: context.loc.settingsPresetLyricsManualHint,
          icon: Icons.edit_off_rounded,
          apply: () => _applyLyrics(
            settings,
            controller,
            autoFill: false,
            gapCheck: false,
          ),
        ),
        SettingsPreset(
          id: 'balanced',
          title: context.loc.settingsPresetLyricsBalanced,
          description: context.loc.settingsPresetLyricsBalancedHint,
          icon: Icons.balance_rounded,
          apply: () => _applyLyrics(
            settings,
            controller,
            autoFill: true,
            gapCheck: true,
          ),
        ),
        SettingsPreset(
          id: 'saver',
          title: context.loc.settingsPresetLyricsSaver,
          description: context.loc.settingsPresetLyricsSaverHint,
          icon: Icons.battery_saver_rounded,
          apply: () => _applyLyrics(
            settings,
            controller,
            autoFill: true,
            gapCheck: false,
          ),
        ),
      ];
    case SettingsSection.localization:
      return const [];
    case SettingsSection.discovery:
      return [
        SettingsPreset(
          id: 'on',
          title: context.loc.settingsPresetLearnOn,
          description: context.loc.settingsPresetLearnOnHint,
          icon: Icons.auto_awesome_rounded,
          apply: () => controller.setUseListeningHistory(true),
        ),
        SettingsPreset(
          id: 'off',
          title: context.loc.settingsPresetLearnOff,
          description: context.loc.settingsPresetLearnOffHint,
          icon: Icons.shield_outlined,
          apply: () => controller.setUseListeningHistory(false),
        ),
      ];
    case SettingsSection.desktop:
      return [
        SettingsPreset(
          id: 'tray',
          title: context.loc.settingsPresetTray,
          description: context.loc.settingsPresetTrayHint,
          icon: Icons.minimize_rounded,
          apply: () => controller.setCloseToTray(true),
        ),
        SettingsPreset(
          id: 'quit',
          title: context.loc.settingsPresetQuit,
          description: context.loc.settingsPresetQuitHint,
          icon: Icons.power_settings_new_rounded,
          apply: () => controller.setCloseToTray(false),
        ),
      ];
    case SettingsSection.overview:
    case SettingsSection.permissions:
    case SettingsSection.sourceHealth:
    case SettingsSection.about:
      return const [];
  }
}

/// The id of the preset the current settings match, or `custom`.
String settingsSelectedPreset(
  SettingsSection section,
  SettingsState settings,
) {
  switch (section) {
    case SettingsSection.appearance:
      return settings.themeMode.name;
    case SettingsSection.library:
      return settings.autoScanOnStartup ? 'auto' : 'manual';
    case SettingsSection.playback:
      if (!settings.autoResumeOnStartup) return 'custom';
      if (settings.replaceQueueOnClick &&
          settings.favoritesDoubleClickPlays &&
          !settings.onlyLikeOnDoubleClick) {
        return 'single';
      }
      if (!settings.replaceQueueOnClick &&
          settings.favoritesDoubleClickPlays &&
          !settings.onlyLikeOnDoubleClick) {
        return 'queue';
      }
      if (!settings.replaceQueueOnClick &&
          !settings.favoritesDoubleClickPlays &&
          settings.onlyLikeOnDoubleClick) {
        return 'favorite';
      }
      return 'custom';
    case SettingsSection.lyrics:
      final config = settings.smartLyrics;
      if (!config.autoFill && !config.gapCheckEnabled) return 'manual';
      if (config.autoFill && config.gapCheckEnabled) return 'balanced';
      if (config.autoFill && !config.gapCheckEnabled) return 'saver';
      return 'custom';
    case SettingsSection.localization:
      return 'custom';
    case SettingsSection.discovery:
      return settings.useListeningHistory ? 'on' : 'off';
    case SettingsSection.desktop:
      return settings.closeToTray ? 'tray' : 'quit';
    case SettingsSection.overview:
    case SettingsSection.permissions:
    case SettingsSection.sourceHealth:
    case SettingsSection.about:
      return 'custom';
  }
}

void _applyPlayback(
  SettingsController controller, {
  required bool replaceQueue,
  required bool favoritesDoubleClick,
  required bool onlyLike,
}) {
  controller.setReplaceQueueOnClick(replaceQueue);
  controller.setFavoritesDoubleClickPlays(favoritesDoubleClick);
  controller.setOnlyLikeOnDoubleClick(onlyLike);
  controller.setAutoResumeOnStartup(true);
}

void _applyLyrics(
  SettingsState settings,
  SettingsController controller, {
  required bool autoFill,
  required bool gapCheck,
}) {
  controller.setSmartLyrics(
    settings.smartLyrics.copyWith(
      autoFill: autoFill,
      gapCheckEnabled: gapCheck,
    ),
  );
}
