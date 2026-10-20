import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/config/app_version.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/desktop/audio_mime_types.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_cards.dart';
import 'package:tune/features/settings/presentation/settings_desktop_card.dart';
import 'package:tune/features/settings/presentation/settings_playback_card.dart';

class SettingsPane extends ConsumerStatefulWidget {
  const SettingsPane({super.key});

  @override
  ConsumerState<SettingsPane> createState() => _SettingsPaneState();
}

class _SettingsPaneState extends ConsumerState<SettingsPane> {
  /// Whether the desktop already opens audio files with Tune.
  bool? _isDefaultPlayer;

  /// Whether the desktop entry of Tune is in place.
  bool _desktopEntryInstalled = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultPlayerState();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final library = ref.watch(
      libraryControllerProvider.select(
        (value) => (
          value.hasValue,
          value.valueOrNull?.isScanning ?? false,
          value.valueOrNull?.isLoading ?? false,
        ),
      ),
    );
    final libraryReady = library.$1;
    final scanning = library.$2;
    final clearing = library.$3;
    final busy = scanning || clearing;
    final settingsController = ref.read(settingsControllerProvider.notifier);

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          CompactTokens.pageGutter,
          CompactTokens.pageTopPadding,
          CompactTokens.pageGutter,
          CompactTokens.pageGutter,
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsPageHeader(version: AppVersion.version),
                const SizedBox(height: CompactTokens.space20),
                SettingsInterfaceCard(
                  themeMode: settings.themeMode,
                  locale: settings.locale,
                  onThemeChanged: settingsController.setThemeMode,
                  onLocaleChanged: settingsController.setLocale,
                ),
                const SizedBox(height: 14),
                SettingsLibraryCard(
                  settings: settings,
                  scanning: scanning,
                  canScan: libraryReady && !busy,
                  onAddFolder: _pickDirectory,
                  onRemoveFolder: settingsController.removeScanPath,
                  onScan: _scan,
                  onClear: libraryReady && !busy ? _clearLibrary : null,
                  onChooseLibraryFolder: _pickLibraryFolder,
                  onResetLibraryFolder: _resetLibraryFolder,
                ),
                const SizedBox(height: 14),
                SettingsPlaybackCard(
                  replaceQueueOnClick: settings.replaceQueueOnClick,
                  onReplaceQueueOnClick:
                      settingsController.setReplaceQueueOnClick,
                ),
                const SizedBox(height: 14),
                SettingsDesktopCard(
                  closeToTray: settings.closeToTray,
                  mediaControlsEnabled: settings.mediaControlsEnabled,
                  isDefaultPlayer: _isDefaultPlayer ?? false,
                  desktopEntryInstalled: _desktopEntryInstalled,
                  onCloseToTrayChanged: settingsController.setCloseToTray,
                  onMediaControlsChanged:
                      settingsController.setMediaControlsEnabled,
                  onSetDefaultPlayer: _canSetDefaultPlayer
                      ? _setDefaultPlayer
                      : null,
                ),
                const SizedBox(height: 14),
                SettingsAboutCard(version: AppVersion.version),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: context.loc.settingsChooseFolder,
    );
    if (path == null || !mounted) return;

    await ref.read(settingsControllerProvider.notifier).addScanPath(path);
    if (!mounted) return;
    _showMessage(context.loc.settingsFolderAdded);
  }

  /// Picks the folder the app writes the files it fetches into.
  Future<void> _pickLibraryFolder() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: context.loc.settingsChangeLibraryFolder,
    );
    if (path == null || !mounted) return;

    await ref.read(settingsControllerProvider.notifier).setLibraryFolder(path);
  }

  /// Puts the files back into the music library of the machine.
  Future<void> _resetLibraryFolder() async {
    await ref.read(settingsControllerProvider.notifier).setLibraryFolder(null);
  }

  Future<void> _scan() async {
    final settings = ref.read(settingsControllerProvider);
    await ref
        .read(libraryControllerProvider.notifier)
        .scan(settings.effectiveScanPaths);
    if (!mounted) return;
    final state = ref.read(libraryControllerProvider).valueOrNull;
    _showMessage(
      state?.errorMessage ??
          state?.statusMessage ??
          context.loc.settingsScanDone,
    );
  }

  Future<void> _clearLibrary() async {
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
    _showMessage(state?.errorMessage ?? context.loc.settingsLibraryCleared);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  /// Whether the desktop can name Tune as the default player.
  bool get _canSetDefaultPlayer {
    return ref.read(defaultPlayerServiceProvider).isSupported;
  }

  /// Reads whether the desktop already opens audio files with Tune.
  Future<void> _loadDefaultPlayerState() async {
    final service = ref.read(defaultPlayerServiceProvider);
    if (!service.isSupported) return;

    final installed = await service.isDesktopEntryInstalled();
    if (!mounted) return;
    setState(() => _desktopEntryInstalled = installed);
    if (!installed) return;

    final isDefault = await service.isDefaultHandler('audio/mpeg');
    if (!mounted) return;
    setState(() => _isDefaultPlayer = isDefault);
  }

  /// Makes Tune the program the desktop opens audio files with.
  Future<void> _setDefaultPlayer() async {
    final service = ref.read(defaultPlayerServiceProvider);

    final installed = await service.isDesktopEntryInstalled();
    if (!installed) {
      if (!mounted) return;
      _showMessage(context.loc.settingsDefaultPlayerFailed);
      return;
    }

    var succeeded = true;
    for (final mimeType in supportedAudioMimeTypes) {
      succeeded = await service.makeDefaultHandler(mimeType) && succeeded;
    }
    if (!mounted) return;

    setState(() => _isDefaultPlayer = succeeded);
    _showMessage(
      succeeded
          ? context.loc.settingsDefaultPlayerDone
          : context.loc.settingsDefaultPlayerFailed,
    );
  }
}
