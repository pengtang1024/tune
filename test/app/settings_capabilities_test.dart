import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/core/config/app_capabilities.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/settings/presentation/settings_pane.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../services/fake_default_player_service.dart';
import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';

/// The settings page draws only what the build actually wires up.
void main() {
  Future<void> openSettings(
    WidgetTester tester,
    AppCapabilities capabilities,
  ) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          persistenceServiceProvider.overrideWithValue(FakePersistenceService()),
          audioPlayerServiceProvider.overrideWithValue(audio),
          defaultPlayerServiceProvider.overrideWithValue(
            FakeDefaultPlayerService(),
          ),
          libraryControllerProvider.overrideWith(
            () => FakeLibraryController(const LibraryState()),
          ),
        ],
        child: MaterialApp(
          theme: CompactTheme.light,
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SettingsPane(capabilities: capabilities)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Windows leaves out the tray, the media controls and the updater', (
    tester,
  ) async {
    await openSettings(tester, AppCapabilities.forPlatform(AppPlatform.windows));

    // Nothing under the desktop group is wired up on Windows yet, so the
    // section itself is gone instead of holding dead switches.
    expect(find.byKey(const ValueKey('settings-nav-desktop')), findsNothing);
    expect(find.byKey(const ValueKey('settings-card-desktop')), findsNothing);

    // The update card is part of the about block and follows the updater
    // capability.
    expect(find.byKey(const ValueKey('settings-card-update')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Linux keeps the desktop group and the updater', (tester) async {
    await openSettings(tester, AppCapabilities.forPlatform(AppPlatform.linux));

    expect(find.byKey(const ValueKey('settings-nav-desktop')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-card-update')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phone keeps the page but no desktop group', (tester) async {
    await openSettings(tester, AppCapabilities.forPlatform(AppPlatform.android));

    expect(find.byKey(const ValueKey('settings-nav-desktop')), findsNothing);
    expect(find.byKey(const ValueKey('settings-card-update')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class FakeLibraryController extends LibraryController {
  FakeLibraryController(this.seed);

  final LibraryState seed;

  @override
  Future<LibraryState> build() async => seed;

  @override
  Future<void> scan(List<String> paths, {bool auto = false}) async {}

  @override
  Future<void> setQuery(String query) async {
    state = AsyncData((state.valueOrNull ?? seed).copyWith(query: query));
  }
}
