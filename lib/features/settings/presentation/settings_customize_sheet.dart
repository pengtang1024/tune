import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/config/app_capabilities.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/library/application/library_cache_limit_provider.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_cards.dart';
import 'package:tune/features/settings/presentation/settings_desktop_card.dart';
import 'package:tune/features/settings/presentation/settings_discovery_card.dart';
import 'package:tune/features/settings/presentation/settings_local_components_card.dart';
import 'package:tune/features/settings/presentation/settings_localization_card.dart';
import 'package:tune/features/settings/presentation/settings_permissions_card.dart';
import 'package:tune/features/settings/presentation/settings_playback_card.dart';
import 'package:tune/features/settings/presentation/settings_section_catalog.dart';
import 'package:tune/features/settings/presentation/settings_smart_lyrics_card.dart';
import 'package:tune/features/settings/presentation/settings_source_health_card.dart';
import 'package:tune/shared/ui/settings_card_shell.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The sheet the customize button of a card opens.
void showSettingsCustomizeSheet({
  required BuildContext context,
  required SettingsSection section,
  required Widget child,
}) {
  final width = MediaQuery.sizeOf(context).width;
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      alignment: Alignment.centerRight,
      insetPadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: math.min(640, width),
        height: MediaQuery.sizeOf(context).height,
        child: Material(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  CompactTokens.space16,
                  CompactTokens.space12,
                  CompactTokens.space8,
                  CompactTokens.space8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        settingsSectionLabel(context, section),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TuneTooltip(
                      message: context.loc.cancel,
                      child: IconButton(
                        key: const ValueKey('settings-custom-close'),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(CompactTokens.space16),
                  child: SettingsSheetScope(inSheet: true, child: child),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The body of the customize sheet: the card of one section.
class SettingsCustomizeCard extends ConsumerWidget {
  final SettingsSection section;
  final AppCapabilities capabilities;
  final bool? isDefaultPlayer;
  final bool desktopEntryInstalled;
  final VoidCallback onPickDirectory;
  final Future<void> Function() onScan;
  final Future<void> Function() onClear;
  final VoidCallback onChooseLibraryFolder;
  final Future<void> Function() onResetLibraryFolder;
  final VoidCallback? onSetDefaultPlayer;

  const SettingsCustomizeCard({
    super.key,
    required this.section,
    required this.capabilities,
    required this.isDefaultPlayer,
    required this.desktopEntryInstalled,
    required this.onPickDirectory,
    required this.onScan,
    required this.onClear,
    required this.onChooseLibraryFolder,
    required this.onResetLibraryFolder,
    required this.onSetDefaultPlayer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final library = ref.watch(
      libraryControllerProvider.select(
        (value) => (
          value.hasValue,
          value.valueOrNull?.isScanning ?? false,
          value.valueOrNull?.isLoading ?? false,
        ),
      ),
    );
    return switch (section) {
      SettingsSection.appearance => SettingsInterfaceCard(
        themeMode: settings.themeMode,
        locale: settings.locale,
        onThemeChanged: controller.setThemeMode,
        onLocaleChanged: controller.setLocale,
      ),
      SettingsSection.library => SettingsLibraryCard(
        settings: settings,
        scanning: library.$2,
        canScan: library.$1 && !library.$2 && !library.$3,
        onAddFolder: onPickDirectory,
        onRemoveFolder: controller.removeScanPath,
        onScan: onScan,
        onClear: library.$1 && !library.$2 && !library.$3 ? onClear : null,
        onChooseLibraryFolder: onChooseLibraryFolder,
        onResetLibraryFolder: onResetLibraryFolder,
        cacheLimit: ref.watch(libraryCacheLimitProvider),
        onCacheLimitChanged: ref.read(libraryCacheLimitProvider.notifier).set,
      ),
      SettingsSection.playback => SettingsPlaybackCard(
        autoResumeOnStartup: settings.autoResumeOnStartup,
        replaceQueueOnClick: settings.replaceQueueOnClick,
        onlyLikeOnDoubleClick: settings.onlyLikeOnDoubleClick,
        favoritesDoubleClickPlays: settings.favoritesDoubleClickPlays,
        onAutoResumeOnStartup: controller.setAutoResumeOnStartup,
        onReplaceQueueOnClick: controller.setReplaceQueueOnClick,
        onOnlyLikeOnDoubleClick: controller.setOnlyLikeOnDoubleClick,
        onFavoritesDoubleClickPlays: controller.setFavoritesDoubleClickPlays,
      ),
      SettingsSection.lyrics => const SettingsSmartLyricsCard(),
      SettingsSection.localization => const SettingsLocalizationCard(),
      SettingsSection.components => const SettingsLocalComponentsCard(),
      SettingsSection.discovery => const SettingsDiscoveryCard(),
      SettingsSection.desktop => SettingsDesktopCard(
        capabilities: capabilities,
        closeToTray: settings.closeToTray,
        mediaControlsEnabled: settings.mediaControlsEnabled,
        isDefaultPlayer: isDefaultPlayer ?? false,
        desktopEntryInstalled: desktopEntryInstalled,
        onCloseToTrayChanged: controller.setCloseToTray,
        onMediaControlsChanged: controller.setMediaControlsEnabled,
        onSetDefaultPlayer: onSetDefaultPlayer,
      ),
      SettingsSection.sourceHealth => const SettingsSourceHealthCard(),
      SettingsSection.permissions => const SettingsPermissionsCard(),
      SettingsSection.overview ||
      SettingsSection.about => const SizedBox.shrink(),
    };
  }
}
