import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/features/player/presentation/player_dock.dart';
import 'package:tune/features/queue/presentation/queue_panel.dart';
import 'package:tune/features/shell/presentation/app_bottom_bar.dart';
import 'package:tune/features/shell/presentation/app_sidebar.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';
import 'package:tune/features/shell/presentation/mini_player_bar.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';

/// A phone swaps the rail for a bar and the dock for a single row.
void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    required Size size,
    required bool mobile,
  }) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          persistenceServiceProvider.overrideWithValue(
            FakePersistenceService(),
          ),
          audioPlayerServiceProvider.overrideWithValue(audio),
        ],
        child: MaterialApp(
          theme: CompactTheme.light,
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CompactShell(
            currentPath: '/library',
            mobile: mobile,
            child: const Center(child: Text('page')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a phone draws the bar under the content and no rail', (
    tester,
  ) async {
    await pumpShell(tester, size: const Size(390, 844), mobile: true);

    expect(find.byType(AppBottomBar), findsOneWidget);
    expect(find.byType(MiniPlayerBar), findsOneWidget);
    expect(find.byType(AppSidebar), findsNothing);
    expect(find.byType(PlayerDock), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a narrow desktop window keeps the rail and the dock', (
    tester,
  ) async {
    // The window of the desktop never goes below 760 wide, where the rail
    // has already dropped its labels.
    await pumpShell(tester, size: const Size(760, 844), mobile: false);

    expect(find.byType(AppBottomBar), findsNothing);
    expect(find.byType(AppSidebar), findsOneWidget);
    expect(find.byType(PlayerDock), findsOneWidget);
  });

  testWidgets('a phone bar lists every destination', (tester) async {
    await pumpShell(tester, size: const Size(390, 844), mobile: true);

    // The bar holds the pages of the rail, in the same order.
    for (final path in [
      '/discover',
      '/library',
      '/favorites',
      '/sources',
      '/settings',
    ]) {
      expect(
        find.byKey(ValueKey('bottom-bar-$path')),
        findsOneWidget,
        reason: path,
      );
    }
  });

  testWidgets('the queue icon of the phone bar opens the bottom drawer', (
    tester,
  ) async {
    await pumpShell(tester, size: const Size(390, 844), mobile: true);

    await tester.tap(find.byKey(const ValueKey('mini-queue')));
    await tester.pumpAndSettle();

    expect(find.byType(QueuePanel), findsOneWidget);
    // The bar stays usable under the drawer.
    expect(find.byType(AppBottomBar), findsOneWidget);
  });
}
