import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/domain/models/source_health_weights.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_config.dart';

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

  test('a double click in favorites plays and replaces the queue by default',
      () async {
    final persistence = FakePersistenceService();

    final controller = SettingsController(persistence);
    addTearDown(controller.dispose);

    expect(controller.state.favoritesDoubleClickPlays, isTrue);

    await controller.setFavoritesDoubleClickPlays(false);
    expect(controller.state.favoritesDoubleClickPlays, isFalse);

    final reloaded = SettingsController(persistence);
    addTearDown(reloaded.dispose);
    expect(reloaded.state.favoritesDoubleClickPlays, isFalse);
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

  test('auto resuming the last session is on by default and survives', () async {
    final persistence = FakePersistenceService();

    final controller = SettingsController(persistence);
    expect(controller.state.autoResumeOnStartup, isTrue);

    await controller.setAutoResumeOnStartup(false);
    controller.dispose();

    final reloaded = SettingsController(persistence);
    addTearDown(reloaded.dispose);
    expect(reloaded.state.autoResumeOnStartup, isFalse);
  });

  test('the old restore switch still answers after the rename', () async {
    final persistence = FakePersistenceService();
    await persistence.setBool('restore_playback_on_startup', false);

    final controller = SettingsController(persistence);
    addTearDown(controller.dispose);
    expect(controller.state.autoResumeOnStartup, isFalse);
  });

  test('local listening history is off by default and survives', () async {
    final persistence = FakePersistenceService();

    final controller = SettingsController(persistence);
    expect(controller.state.useListeningHistory, isFalse);

    await controller.setUseListeningHistory(true);
    controller.dispose();

    final reloaded = SettingsController(persistence);
    addTearDown(reloaded.dispose);
    expect(reloaded.state.useListeningHistory, isTrue);
  });

  test('the smart lyrics config survives a controller rebuild', () async {
    final persistence = FakePersistenceService();
    final controller = SettingsController(persistence);

    await controller.setSmartLyrics(
      controller.state.smartLyrics.copyWith(
        presetId: 'groq',
        baseUrl: SmartLyricsPreset.byId('groq').baseUrl,
        apiKey: 'sk-test',
      ),
    );
    controller.dispose();

    final reloaded = SettingsController(persistence);
    addTearDown(reloaded.dispose);
    expect(reloaded.state.smartLyrics.presetId, 'groq');
    expect(reloaded.state.smartLyrics.apiKey, 'sk-test');
    expect(reloaded.state.smartLyrics.isConfigured, isTrue);
  });

  test('a broken saved config falls back to the defaults', () {
    final persistence = FakePersistenceService()
      ..setString('smart_lyrics', '{oops');

    final controller = SettingsController(persistence);
    addTearDown(controller.dispose);

    expect(
      controller.state.smartLyrics.baseUrl,
      SmartLyricsConfig().baseUrl,
      reason: 'a broken paste must not take the pipeline down with it',
    );
  });
}
