import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tune/data/services/impl/shared_preferences_service.dart';
import 'package:tune/features/settings/application/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('theme, locale and scan paths survive a controller rebuild', () async {
    SharedPreferences.setMockInitialValues({});
    final persistence = SharedPreferencesService();
    await persistence.init();

    final controller = SettingsController(persistence);
    await controller.setThemeMode(ThemeMode.dark);
    await controller.setLocale(const Locale('zh', 'CN'));
    await controller.addScanPath('/music/extra');
    await controller.setAutoScanOnStartup(false);
    controller.dispose();

    final reloaded = SettingsController(persistence);
    addTearDown(reloaded.dispose);

    expect(reloaded.state.themeMode, ThemeMode.dark);
    expect(reloaded.state.locale, const Locale('zh', 'CN'));
    expect(reloaded.state.customScanPaths, ['/music/extra']);
    expect(reloaded.state.autoScanOnStartup, isFalse);
  });

  test('custom scan paths are deduplicated', () async {
    SharedPreferences.setMockInitialValues({});
    final persistence = SharedPreferencesService();
    await persistence.init();

    final controller = SettingsController(persistence);
    addTearDown(controller.dispose);

    await controller.addScanPath('/music/extra');
    await controller.addScanPath(' /music/extra ');

    expect(controller.state.customScanPaths, ['/music/extra']);
  });
}
