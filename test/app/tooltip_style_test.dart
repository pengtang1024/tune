import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/features/shell/presentation/app_sidebar.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// Guards the hints of the app.
///
/// Five rules are checked:
///
/// * every hint of the theme looks like the same drop of ink, in the light
///   theme and in the dark one,
/// * every hint is a dark card with paper words, so it never turns into a
///   white box,
/// * a hint without words shows nothing at all,
/// * a page that already writes its name does not say it a second time,
/// * no widget writes a hint of its own, so the look stays in one place.
void main() {
  test('every hint of the theme looks like the same drop of ink', () {
    for (final theme in [CompactTheme.light, CompactTheme.dark]) {
      final tooltip = theme.tooltipTheme;

      final decoration = tooltip.decoration;
      expect(decoration, isA<BoxDecoration>());

      final card = decoration! as BoxDecoration;
      expect(card.color, isNotNull, reason: 'a hint needs a background');
      expect(card.borderRadius, isNotNull, reason: 'a hint needs round corners');
      expect(card.border, isA<Border>(), reason: 'a hint needs a rim');
      expect(card.boxShadow, isNotEmpty, reason: 'a hint needs to float');

      // Above the thing it belongs to, so the pointer never covers it.
      expect(tooltip.preferBelow, isFalse);

      // It waits for the pointer and stays long enough to be read.
      expect(tooltip.waitDuration, isNotNull);
      expect(tooltip.waitDuration! > Duration.zero, isTrue);
      expect(tooltip.showDuration, isNotNull);
      expect(tooltip.showDuration! >= const Duration(seconds: 3), isTrue);

      // A long sentence wraps instead of stretching across the window.
      expect(tooltip.constraints, isNotNull);
      expect(tooltip.constraints!.maxWidth, isNotNull);
    }
  });

  test('every hint is a drop of ink that writes in paper', () {
    Color? background(ThemeData theme) {
      final decoration = theme.tooltipTheme.decoration! as BoxDecoration;
      return decoration.color;
    }

    Color? letters(ThemeData theme) => theme.tooltipTheme.textStyle?.color;

    for (final theme in [CompactTheme.light, CompactTheme.dark]) {
      // The hint is ink in both themes: a dark card, never a white box.
      expect(
        background(theme)!.computeLuminance(),
        lessThan(0.2),
        reason: 'the hint has to be a dark card',
      );

      // The letters keep the contrast of the card they sit on.
      expect(
        letters(theme)!.computeLuminance(),
        greaterThan(0.6),
        reason: 'the words have to be readable on the card',
      );
    }
  });

  testWidgets('a hint without words shows nothing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TuneTooltip(message: '   ', child: Text('body'))),
      ),
    );

    expect(find.byType(Tooltip), findsNothing);
    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('a hint with words says them', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TuneTooltip(message: 'Play', child: Text('body'))),
      ),
    );

    expect(find.byType(Tooltip), findsOneWidget);
    expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, 'Play');
  });

  testWidgets('the wide sidebar does not say the name of a page twice', (
    tester,
  ) async {
    await tester.pumpWidget(sidebar(compact: false));

    expect(find.byType(Tooltip), findsNothing);
  });

  testWidgets('the narrow sidebar names the page on the pointer', (tester) async {
    await tester.pumpWidget(sidebar(compact: true));

    expect(find.byType(Tooltip), findsNWidgets(4));
  });

  test('no widget writes a hint of its own', () {
    final offenders = <String>[];

    for (final file in _dartFiles('lib')) {
      if (file.path.endsWith('shared/ui/tune_tooltip.dart')) continue;

      final source = file.readAsStringSync();
      for (final match in RegExp(r'\bTooltip\(').allMatches(source)) {
        final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
        offenders.add('${file.path}:$line');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'a widget writes a hint of its own:\n${offenders.join('\n')}',
    );
  });
}

/// The sidebar of the shell, in the language of the reader.
Widget sidebar({required bool compact}) {
  return MaterialApp(
    theme: CompactTheme.light,
    locale: const Locale('zh', 'CN'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: AppSidebar(currentPath: '/library', compact: compact),
    ),
  );
}

Iterable<File> _dartFiles(String directory) {
  return Directory(directory)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.contains('/l10n/app_localizations'));
}
