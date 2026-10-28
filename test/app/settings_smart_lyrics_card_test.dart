import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_ledger_provider.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_ledger.dart';
import 'package:tune/features/smart_lyrics/presentation/settings_smart_lyrics_card.dart';
import 'package:tune/l10n/app_localizations.dart';

import '../services/fake_persistence.dart';

/// The ledger of the lyrics the library carries, and the key hole the
/// reader pastes theirs into (docs/smart-lyrics.md §7.1, M0+M1).
void main() {
  Future<SettingsController> pumpCard(
    WidgetTester tester, {
    required Future<SmartLyricsLedger> ledger,
  }) async {
    // The provider owns the controller: it disposes it when the scope
    // unmounts, so the test adds no teardown of its own.
    final controller = SettingsController(FakePersistenceService());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          smartLyricsLedgerProvider.overrideWith((ref) => ledger),
          settingsControllerProvider.overrideWith((ref) => controller),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SingleChildScrollView(
            child: SettingsSmartLyricsCard(),
          )),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('the card shows the three counts of the ledger', (tester) async {
    await pumpCard(
      tester,
      ledger: Future.value(const SmartLyricsLedger(total: 400, resolved: 370)),
    );

    expect(find.text('400'), findsOneWidget, reason: 'the whole library');
    expect(find.text('370'), findsOneWidget, reason: 'the tracks with lyrics');
    expect(find.text('30'), findsOneWidget, reason: 'the gap the pipeline fills');
  });

  testWidgets('a ledger that cannot be read shows itself as unavailable', (
    tester,
  ) async {
    final failing = Completer<SmartLyricsLedger>();
    // The provider listens as soon as the card mounts; `.ignore()` keeps the
    // moment before that from reading as an unhandled error.
    failing.future.ignore();
    failing.completeError(StateError('no database'));
    await pumpCard(tester, ledger: failing.future);

    expect(
      find.textContaining('-'),
      findsWidgets,
      reason: 'missing numbers are dashes, not zeros: zero would lie',
    );
  });

  testWidgets('a key pasted turns the pipeline on at once', (tester) async {
    final controller = await pumpCard(
      tester,
      ledger: Future.value(const SmartLyricsLedger(total: 0, resolved: 0)),
    );

    expect(controller.state.smartLyrics.isConfigured, isFalse);

    await tester.enterText(
      find.byKey(const Key('smart-lyrics-api-key')),
      'sk-test',
    );

    expect(controller.state.smartLyrics.apiKey, 'sk-test');
    expect(controller.state.smartLyrics.isConfigured, isTrue);
  });

  testWidgets('a preset picked prefills its endpoint and models', (
    tester,
  ) async {
    final controller = await pumpCard(
      tester,
      ledger: Future.value(const SmartLyricsLedger(total: 0, resolved: 0)),
    );

    await tester.tap(find.byKey(const Key('smart-lyrics-preset')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Groq').last,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(controller.state.smartLyrics.presetId, 'groq');
    expect(
      controller.state.smartLyrics.baseUrl,
      'https://api.groq.com/openai/v1',
    );
  });

  testWidgets('the advanced fold keeps its configuration', (tester) async {
    final controller = await pumpCard(
      tester,
      ledger: Future.value(const SmartLyricsLedger(total: 0, resolved: 0)),
    );

    await tester.tap(find.byKey(const Key('smart-lyrics-advanced')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('smart-lyrics-asr-models')),
      'whisper-1, whisper-large-v3',
    );
    await tester.tap(find.byKey(const Key('smart-lyrics-advanced')));
    await tester.pumpAndSettle();

    expect(
      controller.state.smartLyrics.asrModels,
      ['whisper-1', 'whisper-large-v3'],
    );
  });
}
