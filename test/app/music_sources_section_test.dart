import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/impl/shared_preferences_service.dart';
import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';
import 'package:tune/features/sources/presentation/music_sources_section.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';

void main() {
  late SharedPreferencesService persistence;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    persistence = SharedPreferencesService();
    await persistence.init();
  });

  Widget app(FakeMusicSourcesController controller) {
    return ProviderScope(
      overrides: [
        sharedPreferencesServiceProvider.overrideWithValue(persistence),
        musicSourcesControllerProvider.overrideWith(() => controller),
      ],
      child: MaterialApp(
        theme: CompactTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(child: MusicSourcesSection()),
        ),
      ),
    );
  }

  testWidgets('unconfigured source only enables after saving settings', (
    tester,
  ) async {
    final controller = FakeMusicSourcesController(
      const MusicSourcesState(sources: [BuiltInMusicSources.jamendo]),
    );

    await tester.pumpWidget(app(controller));
    await tester.pumpAndSettle();

    final sourceSwitch = find.byKey(const ValueKey('source-switch-jamendo'));
    expect(tester.widget<Switch>(sourceSwitch).value, isFalse);

    await tester.tap(sourceSwitch);
    await tester.pumpAndSettle();
    expect(find.text('配置 Jamendo'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(controller.enabledChanges, isEmpty);
    expect(tester.widget<Switch>(sourceSwitch).value, isFalse);

    await tester.tap(sourceSwitch);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'client-id');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(controller.settingsChanges['jamendo']?['clientId'], 'client-id');
    expect(controller.enabledChanges, [true]);
    expect(tester.widget<Switch>(sourceSwitch).value, isTrue);
    expect(tester.takeException(), isNull);
  });
}

class FakeMusicSourcesController extends MusicSourcesController {
  FakeMusicSourcesController(this.seed);

  final MusicSourcesState seed;
  final List<bool> enabledChanges = [];
  final Map<String, Map<String, String>> settingsChanges = {};

  @override
  Future<MusicSourcesState> build() async => seed;

  @override
  Future<void> setEnabled(String sourceId, bool enabled) async {
    enabledChanges.add(enabled);
    final current = state.valueOrNull ?? seed;
    state = AsyncData(
      current.copyWith(
        sources: [
          for (final source in current.sources)
            source.id == sourceId ? source.copyWith(enabled: enabled) : source,
        ],
      ),
    );
  }

  @override
  Future<void> updateSettings(
    String sourceId,
    Map<String, String> settings,
  ) async {
    settingsChanges[sourceId] = Map.of(settings);
    final current = state.valueOrNull ?? seed;
    state = AsyncData(
      current.copyWith(
        sources: [
          for (final source in current.sources)
            source.id == sourceId
                ? source.copyWith(settings: Map.unmodifiable(settings))
                : source,
        ],
      ),
    );
  }
}
