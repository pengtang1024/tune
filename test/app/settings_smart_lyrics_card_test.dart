import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_ledger_provider.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_ledger.dart';
import 'package:tune/features/smart_lyrics/presentation/settings_smart_lyrics_card.dart';
import 'package:tune/l10n/app_localizations.dart';

/// The ledger of the lyrics the library carries, as the settings page shows
/// it (docs/smart-lyrics.md §7.2, the account of M0).
void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required Future<SmartLyricsLedger> ledger,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [smartLyricsLedgerProvider.overrideWith((ref) => ledger)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SettingsSmartLyricsCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
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

    await tester.pumpAndSettle();

    expect(
      find.textContaining('-'),
      findsWidgets,
      reason: 'missing numbers are dashes, not zeros: zero would lie',
    );
  });
}
