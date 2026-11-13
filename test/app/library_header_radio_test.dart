import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/features/library/presentation/library_header.dart';
import 'package:tune/l10n/app_localizations.dart';

/// The station entry of the library header: it is offered only while the
/// library holds a station, and a click hands the page the same filter the
/// panel writes.
void main() {
  Widget app({required VoidCallback? onRadio, bool radioActive = false}) {
    return MaterialApp(
      theme: CompactTheme.light,
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 900,
          child: LibraryHeader(
            summary: '3 首歌曲 · 1 张专辑 · 1 个音源',
            onAddAll: null,
            onScan: () {},
            scanning: false,
            onSearchOnline: null,
            radioActive: radioActive,
            onRadio: onRadio,
            treeExpanded: false,
            onToggleTree: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('the station entry is left out while there is no station', (
    tester,
  ) async {
    await tester.pumpWidget(app(onRadio: null));
    await tester.pumpAndSettle();

    expect(find.text('电台'), findsNothing);
  });

  testWidgets('the station entry narrows the page on a click', (tester) async {
    var taps = 0;
    await tester.pumpWidget(app(onRadio: () => taps++));
    await tester.pumpAndSettle();

    expect(find.text('电台'), findsOneWidget);
    expect(find.byIcon(Icons.podcasts_rounded), findsOneWidget);

    await tester.tap(find.text('电台'));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the active entry says the page is already narrowed', (
    tester,
  ) async {
    await tester.pumpWidget(app(onRadio: () {}, radioActive: true));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.radio_rounded), findsOneWidget);
    expect(find.byIcon(Icons.podcasts_rounded), findsNothing);
  });
}
