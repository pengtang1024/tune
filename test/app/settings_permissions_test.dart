import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/mobile_permissions_service.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/data/services/providers/mobile_permissions_providers.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/settings/presentation/settings_permissions_card.dart';
import 'package:tune/features/settings/presentation/settings_pane.dart';
import 'package:tune/core/config/app_capabilities.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../services/fake_default_player_service.dart';
import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'mobile_permissions_fake.dart';

/// The permissions card asks the platform, and offers the way back when the
/// dialog may no longer be shown.
void main() {
  Future<FakeMobilePermissionsService> openPermissions(
    WidgetTester tester, {
    required AppCapabilities capabilities,
    required FakeMobilePermissionsService permissions,
  }) async {
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
          mobilePermissionsServiceProvider.overrideWithValue(permissions),
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
    return permissions;
  }

  testWidgets('only Android shows the permissions section', (tester) async {
    await openPermissions(
      tester,
      capabilities: AppCapabilities.forPlatform(AppPlatform.linux),
      permissions: FakeMobilePermissionsService(),
    );
    expect(find.byKey(const ValueKey('settings-nav-permissions')), findsNothing);

    await openPermissions(
      tester,
      capabilities: AppCapabilities.forPlatform(AppPlatform.android),
      permissions: FakeMobilePermissionsService(),
    );
    expect(
      find.byKey(const ValueKey('settings-nav-permissions')),
      findsOneWidget,
    );
  });

  testWidgets('a refused permission sends the reader to the system settings', (
    tester,
  ) async {
    final permissions = FakeMobilePermissionsService(
      notifications: MobilePermissionStatus.denied,
      mediaAudio: MobilePermissionStatus.permanentlyDenied,
    );
    await openPermissions(
      tester,
      capabilities: AppCapabilities.forPlatform(AppPlatform.android),
      permissions: permissions,
    );

    // Searching for the section is how a reader reaches it on a narrow
    // window; it also keeps the card in the built part of the body.
    await tester.enterText(find.byType(TextField).first, '权限');
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPermissionsCard), findsOneWidget);
    // The media row was refused for good, so it offers the settings page
    // instead of a dialog that Android would not show.
    expect(find.text('去设置'), findsOneWidget);
    expect(find.text('允许'), findsOneWidget);

    await tester.tap(find.text('去设置'));
    await tester.pumpAndSettle();
    expect(permissions.openedSettings, 1);
  });

  testWidgets('a granted permission offers no button', (tester) async {
    await openPermissions(
      tester,
      capabilities: AppCapabilities.forPlatform(AppPlatform.android),
      permissions: FakeMobilePermissionsService(),
    );

    await tester.enterText(find.byType(TextField).first, '权限');
    await tester.pumpAndSettle();

    expect(find.text('已允许'), findsNWidgets(2));
    expect(find.text('允许'), findsNothing);
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
