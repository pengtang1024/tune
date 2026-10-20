import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/music_scanner_config.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/data/services/theme_service.dart';
import 'package:tune/features/settings/domain/settings_state.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/utils/logger.dart';

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
      final persistence = ref.watch(persistenceServiceProvider);
      return SettingsController(persistence);
    });

/// Owns user preferences that affect the app shell.
///
/// The old AppBar state mixed title, route, unread count, user profile and
/// preferences. This controller keeps only the settings that actually drive
/// the compact player: theme, locale and custom scan paths.
class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._persistence)
    : _themeService = ThemeService(persistenceService: _persistence),
      super(
        SettingsState(
          themeMode: ThemeService(
            persistenceService: _persistence,
          ).getThemeMode(),
          locale: _readLocale(_persistence),
          defaultScanPaths: MusicScannerConfig.getDefaultMusicPaths(),
          customScanPaths: List.unmodifiable(
            _persistence.getStringList('custom_scan_paths') ?? const [],
          ),
          autoScanOnStartup:
              _persistence.getBool('auto_scan_on_startup') ?? true,
          closeToTray: _persistence.getBool('close_to_tray') ?? true,
          mediaControlsEnabled:
              _persistence.getBool('media_controls_enabled') ?? true,
          replaceQueueOnClick:
              _persistence.getBool('replace_queue_on_click') ?? false,
          libraryFolder: _persistence.getString(LibraryPaths.rootKey),
          defaultLibraryFolder:
              MusicScannerConfig.getDefaultMusicLibrary() ?? '',
        ),
      ) {
    // The string table follows the language of the settings right away, so a
    // service that reads a translated text answers in the language of the
    // user even before the first frame is drawn.
    AppStrings.use(state.locale);
  }

  final PersistenceService _persistence;
  final ThemeService _themeService;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state.themeMode == mode) return;
    state = state.copyWith(themeMode: mode);
    await _themeService.saveThemeMode(mode);
  }

  Future<void> setLocale(Locale locale) async {
    if (state.locale == locale) return;
    state = state.copyWith(locale: locale);
    // The string table follows the language right away, so a service that
    // reads a translated text never answers in the language of before.
    AppStrings.use(locale);
    await _persistence.setString('language_code', locale.languageCode);
    if (locale.countryCode == null) {
      await _persistence.remove('country_code');
    } else {
      await _persistence.setString('country_code', locale.countryCode!);
    }
  }

  Future<void> setAutoScanOnStartup(bool value) async {
    if (state.autoScanOnStartup == value) return;
    state = state.copyWith(autoScanOnStartup: value);
    await _persistence.setBool('auto_scan_on_startup', value);
  }

  /// Sets whether closing the window only hides it.
  Future<void> setCloseToTray(bool value) async {
    if (state.closeToTray == value) return;
    state = state.copyWith(closeToTray: value);
    await _persistence.setBool('close_to_tray', value);
  }

  /// Sets whether the player shows up in the media controls of the system.
  Future<void> setMediaControlsEnabled(bool value) async {
    if (state.mediaControlsEnabled == value) return;
    state = state.copyWith(mediaControlsEnabled: value);
    await _persistence.setBool('media_controls_enabled', value);
  }

  /// Sets whether a single click on a track replaces the play queue.
  Future<void> setReplaceQueueOnClick(bool value) async {
    if (state.replaceQueueOnClick == value) return;
    state = state.copyWith(replaceQueueOnClick: value);
    await _persistence.setBool('replace_queue_on_click', value);
  }

  /// Sets the folder the app writes the files it fetches into.
  ///
  /// A folder of `null` puts the files back into the music library of the
  /// machine.
  Future<void> setLibraryFolder(String? folder) async {
    final cleaned = folder?.trim();
    if ((cleaned == null || cleaned.isEmpty) && state.libraryFolder == null) {
      return;
    }
    if (cleaned == state.libraryFolder) return;

    state = state.copyWith(libraryFolder: cleaned);
    if (cleaned == null || cleaned.isEmpty) {
      await _persistence.remove(LibraryPaths.rootKey);
    } else {
      await _persistence.setString(LibraryPaths.rootKey, cleaned);
    }
  }

  /// The preferences of the user right now.
  ///
  /// The state of a state holder is protected, so callers outside of the
  /// controller read it through this door.
  SettingsState get snapshot => state;

  Future<void> addScanPath(String path) async {
    final normalized = path.trim();
    if (normalized.isEmpty || state.customScanPaths.contains(normalized)) {
      return;
    }
    final paths = List<String>.unmodifiable([
      ...state.customScanPaths,
      normalized,
    ]);
    state = state.copyWith(customScanPaths: paths);
    await _persistence.setStringList('custom_scan_paths', paths);
  }

  Future<void> removeScanPath(String path) async {
    if (!state.customScanPaths.contains(path)) return;
    final paths = List<String>.unmodifiable(
      state.customScanPaths.where((item) => item != path),
    );
    state = state.copyWith(customScanPaths: paths);
    await _persistence.setStringList('custom_scan_paths', paths);
  }

  static Locale _readLocale(PersistenceService persistence) {
    final languageCode = persistence.getString('language_code');
    final countryCode = persistence.getString('country_code');

    if (languageCode != null) {
      final persisted = _matchLocale(languageCode, countryCode);
      if (persisted != null) return persisted;
    }

    final system = WidgetsBinding.instance.platformDispatcher.locale;
    return _matchLocale(system.languageCode, system.countryCode) ??
        const Locale('en');
  }

  static Locale? _matchLocale(String languageCode, String? countryCode) {
    final locales = AppLocalizations.supportedLocales;

    if (countryCode != null) {
      for (final locale in locales) {
        if (locale.languageCode == languageCode &&
            locale.countryCode == countryCode) {
          return locale;
        }
      }
    }

    // The compact settings UI exposes zh_CN rather than the generic zh locale.
    if (languageCode == 'zh') return const Locale('zh', 'CN');

    for (final locale in locales) {
      if (locale.languageCode == languageCode) {
        return locale;
      }
    }

    return null;
  }

  @override
  void dispose() {
    Log.info('SettingsController disposed');
    super.dispose();
  }
}
