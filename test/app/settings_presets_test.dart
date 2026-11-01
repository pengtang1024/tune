import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_pane.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../services/fake_persistence.dart';

class _EmptyLibrary extends LibraryController {
  @override
  Future<LibraryState> build() async => const LibraryState();

  @override
  Future<void> scan(List<String> paths, {bool auto = false}) async {}
}

/// The presets of docs/settings-redesign.md: one click sets a bundle of
/// behaviour fields, and the section rail narrows with the search.
void main() {
  Widget app() => ProviderScope(
    overrides: [
      persistenceServiceProvider.overrideWithValue(FakePersistenceService()),
      libraryControllerProvider.overrideWith(_EmptyLibrary.new),
    ],
    child: MaterialApp(
      theme: CompactTheme.light,
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SettingsPane()),
    ),
  );

  testWidgets('a playback preset sets the whole bundle', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsPane)),
    );

    await tester.tap(find.byKey(const ValueKey('settings-nav-playback')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('单曲优先'));
    await tester.pumpAndSettle();

    final settings = container.read(settingsControllerProvider);
    expect(settings.replaceQueueOnClick, isTrue);
    expect(settings.favoritesDoubleClickPlays, isTrue);
    expect(settings.onlyLikeOnDoubleClick, isFalse);
    expect(settings.autoResumeOnStartup, isTrue);
  });

  testWidgets('the search narrows the section rail', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '桌面');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('settings-nav-desktop')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('settings-nav-playback')),
      findsNothing,
    );
  });
}
