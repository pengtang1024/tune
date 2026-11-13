import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/config/app_capabilities.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/desktop/audio_mime_types.dart';
import 'package:tune/data/services/mobile_permissions_service.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/data/services/providers/saf_method_channel_provider.dart';
import 'package:tune/domain/models/localization_config.dart';
import 'package:tune/domain/models/smart_lyrics_config.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/settings/application/mobile_permissions_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_section_catalog.dart';
import 'package:tune/features/settings/presentation/source_health_weights_sheet.dart';
import 'package:tune/utils/logger.dart';

/// The work the settings page does besides drawing: picking folders,
/// scanning, clearing, setting the default player and resetting sections.
///
/// The page keeps the state; this mixin only holds the actions, so the page
/// file is left with its layout and its scroll spy.
mixin SettingsPaneActions<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// The capabilities of the build being drawn.
  AppCapabilities get capabilities;

  /// Whether this app is already the default player, if that was checked.
  bool? get isDefaultPlayer;
  set isDefaultPlayer(bool? value);

  /// Whether the desktop entry was installed the last time it was checked.
  bool get desktopEntryInstalled;
  set desktopEntryInstalled(bool value);

  /// Shows a short message at the bottom of the page.
  void showSettingsMessage(String message);

  bool get canSetDefaultPlayer =>
      ref.read(defaultPlayerServiceProvider).isSupported;

  Future<void> pickDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: context.loc.settingsChooseFolder,
    );
    if (path == null || !mounted) return;

    await ref.read(settingsControllerProvider.notifier).addScanPath(path);
    if (!mounted) return;
    showSettingsMessage(context.loc.settingsFolderAdded);
  }

  Future<void> pickLibraryFolder() async {
    // A phone has no folder path to hand over: the reader picks a tree in the
    // system picker, and the permission is kept across restarts
    // (docs/android.md §5.1).
    if (capabilities.platform == AppPlatform.android) {
      await _pickSafLibraryFolder();
      return;
    }
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: context.loc.settingsChangeLibraryFolder,
    );
    if (path == null || !mounted) return;

    await ref.read(settingsControllerProvider.notifier).setLibraryFolder(path);
  }

  Future<void> _pickSafLibraryFolder() async {
    try {
      final picked = await ref.read(safMethodChannelProvider).pickDirectory();
      if (picked == null || !mounted) return;
      await ref
          .read(settingsControllerProvider.notifier)
          .setLibraryFolder(picked.uri);
      if (!mounted) return;
      Log.info('音乐库文件夹已选择: ${picked.name} (${picked.writable ? '可写' : '只读'})');
      showSettingsMessage(context.loc.settingsFolderAdded);
    } catch (error) {
      Log.error('选择音乐库文件夹失败: $error');
    }
  }

  Future<void> resetLibraryFolder() async {
    await ref.read(settingsControllerProvider.notifier).setLibraryFolder(null);
  }

  Future<void> scan() async {
    // The files of a phone are behind a runtime permission. The first scan
    // asks for it; a permission refused for good can only be allowed from the
    // system settings, so the page says so instead of scanning an empty
    // library.
    if (capabilities.platform == AppPlatform.android) {
      final granted = await ref
          .read(mobilePermissionsControllerProvider.notifier)
          .ensure(MobilePermission.mediaAudio);
      if (!mounted) return;
      if (!granted) {
        await _showPermissionRefused();
        return;
      }
    }
    final settings = ref.read(settingsControllerProvider);
    await ref
        .read(libraryControllerProvider.notifier)
        .scan(settings.effectiveScanPaths);
    if (!mounted) return;
    final state = ref.read(libraryControllerProvider).valueOrNull;
    showSettingsMessage(
      state?.errorMessage ??
          state?.statusMessage ??
          context.loc.settingsScanDone,
    );
  }

  Future<void> _showPermissionRefused() async {
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.settingsPermissionDialogTitle),
        content: Text(context.loc.settingsPermissionDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.loc.settingsPermissionOpenSettings),
          ),
        ],
      ),
    );
    if (open == true) {
      await ref.read(mobilePermissionsControllerProvider.notifier).openSettings();
    }
  }

  Future<void> clearLibrary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.settingsClearLibraryTitle),
        content: Text(context.loc.settingsClearLibraryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.loc.clear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(libraryControllerProvider.notifier).clearLibrary();
    if (!mounted) return;
    final state = ref.read(libraryControllerProvider).valueOrNull;
    showSettingsMessage(
      state?.errorMessage ?? context.loc.settingsLibraryCleared,
    );
  }

  Future<void> loadDefaultPlayerState() async {
    final service = ref.read(defaultPlayerServiceProvider);
    if (!service.isSupported) return;

    final installed = await service.isDesktopEntryInstalled();
    if (!mounted) return;
    setState(() => desktopEntryInstalled = installed);
    if (!installed) return;

    final isDefault = await service.isDefaultHandler('audio/mpeg');
    if (!mounted) return;
    setState(() => isDefaultPlayer = isDefault);
  }

  Future<void> setDefaultPlayer() async {
    final service = ref.read(defaultPlayerServiceProvider);

    final installed = await service.isDesktopEntryInstalled();
    if (!installed) {
      if (!mounted) return;
      showSettingsMessage(context.loc.settingsDefaultPlayerFailed);
      return;
    }

    var succeeded = true;
    for (final mimeType in supportedAudioMimeTypes) {
      succeeded = await service.makeDefaultHandler(mimeType) && succeeded;
    }
    if (!mounted) return;

    setState(() => isDefaultPlayer = succeeded);
    showSettingsMessage(
      succeeded
          ? context.loc.settingsDefaultPlayerDone
          : context.loc.settingsDefaultPlayerFailed,
    );
  }

  Future<void> confirmReset({
    required bool all,
    required SettingsSection currentSection,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.settingsResetTitle),
        content: Text(
          all
              ? context.loc.settingsResetAllMessage
              : context.loc.settingsResetMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.loc.clear),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final controller = ref.read(settingsControllerProvider.notifier);
    if (all) {
      for (final section in SettingsSection.values) {
        await _resetSection(section, controller);
      }
    } else {
      await _resetSection(currentSection, controller);
    }
  }

  Future<void> _resetSection(
    SettingsSection section,
    SettingsController controller,
  ) async {
    switch (section) {
      case SettingsSection.appearance:
        await controller.setThemeMode(ThemeMode.system);
        await controller.setLocale(const Locale('en'));
      case SettingsSection.library:
        await controller.setAutoScanOnStartup(true);
      case SettingsSection.playback:
        await controller.setReplaceQueueOnClick(false);
        await controller.setOnlyLikeOnDoubleClick(false);
        await controller.setFavoritesDoubleClickPlays(true);
        await controller.setAutoResumeOnStartup(true);
      case SettingsSection.lyrics:
        await controller.setSmartLyrics(const SmartLyricsConfig());
      case SettingsSection.localization:
        await controller.setLocalization(const LocalizationConfig());
      case SettingsSection.discovery:
        await controller.setUseListeningHistory(false);
      case SettingsSection.desktop:
        await controller.setCloseToTray(true);
        await controller.setMediaControlsEnabled(true);
      case SettingsSection.overview:
      case SettingsSection.permissions:
      case SettingsSection.sourceHealth:
      case SettingsSection.about:
        break;
    }
  }

  Future<void> openHealthSheet(BuildContext context) async {
    final weights = ref.read(settingsControllerProvider).sourceHealthWeights;
    final result = await showSourceHealthWeightsSheet(
      context,
      initial: weights,
    );
    if (result == null) return;
    await ref
        .read(settingsControllerProvider.notifier)
        .setSourceHealthWeights(result);
  }
}
