import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/domain/models/equalizer_settings.dart';
import 'package:tune/features/player/application/equalizer_controller.dart';
import 'package:tune/features/player/application/equalizer_providers.dart';
import 'package:tune/features/player/presentation/equalizer_entry.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/equalizer_sheet.dart';

import '../app/fake_audio_equalizer_backend.dart';
import '../services/fake_persistence.dart';

/// Guards the wiring between an entry and the panel.
///
/// The sheet has its own test; what this one covers is the path the player and
/// the settings page share: the entry reads the controller and the platform
/// availability, opens the panel, and every touch inside it lands back on the
/// controller. Without it a working panel behind a dead button would pass.
void main() {
  late FakeAudioEqualizerBackend backend;
  late FakePersistenceService persistence;
  late EqualizerController controller;

  setUp(() {
    backend = FakeAudioEqualizerBackend();
    persistence = FakePersistenceService();
    controller = EqualizerController(persistence, backend);
  });

  // The ProviderScope owns the controller and disposes it on teardown.

  Future<void> pumpEntry(WidgetTester tester, {bool available = true}) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          equalizerControllerProvider.overrideWith((ref) => controller),
          equalizerAvailableProvider.overrideWithValue(available),
        ],
        child: MaterialApp(
          theme: CompactTheme.light,
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) => Center(
                child: TextButton(
                  onPressed: () => openEqualizerPanel(context, ref),
                  child: const Text('均衡器入口'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('均衡器入口'));
    await tester.pumpAndSettle();
  }

  testWidgets('the entry opens the panel the controller fills', (tester) async {
    await pumpEntry(tester);

    expect(find.byType(EqualizerSheet), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(10));
    expect(controller.state.isFlat, isTrue);
  });

  testWidgets('a curve picked in the panel reaches the controller', (
    tester,
  ) async {
    await pumpEntry(tester);

    await tester.tap(find.text('摇滚'));
    await tester.pumpAndSettle();

    // A curve changes what the panel shows; the switch above it is still the
    // only thing that decides whether it is heard, so picking one must not
    // silently turn the feature on.
    expect(controller.state.presetId, EqualizerPresets.rockId);
    expect(controller.state.enabled, isFalse);
    expect(controller.state.gains, EqualizerPresets.rock.gains);
  });

  testWidgets('the switch of the panel turns the equalizer on', (
    tester,
  ) async {
    await pumpEntry(tester);
    expect(controller.state.enabled, isFalse, reason: 'the feature ships off');

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(controller.state.enabled, isTrue);
  });

  testWidgets('reset returns a moved curve to flat', (tester) async {
    await pumpEntry(tester);

    await tester.tap(find.text('重低音'));
    await tester.pumpAndSettle();
    expect(controller.state.isFlat, isFalse);

    await tester.tap(find.text('重置'));
    await tester.pumpAndSettle();

    expect(controller.state.isFlat, isTrue);
  });

  testWidgets('a platform without a backend still opens, as unavailable', (
    tester,
  ) async {
    await pumpEntry(tester, available: false);

    expect(find.byType(EqualizerSheet), findsOneWidget);
    expect(find.text('这个平台的播放后端不支持均衡器'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(10));
  });
}
