import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/music_scanner_config.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/data/services/theme_service.dart';
import 'package:tune/features/settings/domain/settings_state.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/utils/logger.dart';

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
      final persistence = ref.watch(sharedPreferencesServiceProvider);
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
        ),
      );

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
