import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/domain/models/source_health_weights.dart';

import '../services/fake_persistence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('theme, locale and scan paths survive a controller rebuild', () async {
    final persistence = FakePersistenceService();

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
    final persistence = FakePersistenceService();

    final controller = SettingsController(persistence);
    addTearDown(controller.dispose);

    await controller.addScanPath('/music/extra');
    await controller.addScanPath(' /music/extra ');

    expect(controller.state.customScanPaths, ['/music/extra']);
  });

  test('a click keeps the queue until the user asks for the other', () async {
    final persistence = FakePersistenceService();

    final controller = SettingsController(persistence);
    addTearDown(controller.dispose);

    expect(controller.state.replaceQueueOnClick, isFalse);

    await controller.setReplaceQueueOnClick(true);
    expect(controller.state.replaceQueueOnClick, isTrue);
  });

  test('the click behavior survives a controller rebuild', () async {
    final persistence = FakePersistenceService();

    final controller = SettingsController(persistence);
    await controller.setReplaceQueueOnClick(true);
    controller.dispose();

    final reloaded = SettingsController(persistence);
    addTearDown(reloaded.dispose);

    expect(reloaded.state.replaceQueueOnClick, isTrue);
  });

  test('a double click plays and likes the track by default', () async {
    final persistence = FakePersistenceService();

    final controller = SettingsController(persistence);
    addTearDown(controller.dispose);

    expect(controller.state.onlyLikeOnDoubleClick, isFalse);

    await controller.setOnlyLikeOnDoubleClick(true);
    expect(controller.state.onlyLikeOnDoubleClick, isTrue);
  });

  test('the double click behavior survives a controller rebuild', () async {
    final persistence = FakePersistenceService();

    final controller = SettingsController(persistence);
    await controller.setOnlyLikeOnDoubleClick(true);
    controller.dispose();

    final reloaded = SettingsController(persistence);
    addTearDown(reloaded.dispose);

    expect(reloaded.state.onlyLikeOnDoubleClick, isTrue);
  });

  test('the health weights survive a controller rebuild', () async {
    final persistence = FakePersistenceService();
    final controller = SettingsController(persistence);
    addTearDown(controller.dispose);

    final weights = SourceHealthWeights.defaults.copyWith(
      stability: 40,
      activity: 0,
    );
    await controller.setSourceHealthWeights(weights);

    final reloaded = SettingsController(persistence);
    addTearDown(reloaded.dispose);
    expect(reloaded.state.sourceHealthWeights.stability, 40);
    expect(reloaded.state.sourceHealthWeights.activity, 0);
  });

  test('resuming the last session is on by default and survives', () async {
    final persistence = FakePersistenceService();

    final controller = SettingsController(persistence);
    expect(controller.state.restorePlaybackOnStartup, isTrue);

    await controller.setRestorePlaybackOnStartup(false);
    controller.dispose();

    final reloaded = SettingsController(persistence);
    addTearDown(reloaded.dispose);
    expect(reloaded.state.restorePlaybackOnStartup, isFalse);
  });
}
