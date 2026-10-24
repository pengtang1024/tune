import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/features/shell/presentation/app_sidebar.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// Guards the hints of the app.
///
/// Seven rules are checked:
///
/// * every hint of the theme looks like the same drop of ink, in the light
///   theme and in the dark one,
/// * every hint is a dark card with paper words, so it never turns into a
///   white box,
/// * the hint takes the card of the theme the app is in,
/// * a hint that is open while the theme changes stays a drop of ink,
/// * a hint without words shows nothing at all,
/// * a page that already writes its name does not say it a second time,
/// * no widget writes a hint of its own, so the look stays in one place.
void main() {
  test('every hint of the theme looks like the same card', () {
    for (final theme in [CompactTheme.light, CompactTheme.dark]) {
      final tooltip = theme.tooltipTheme;

      final decoration = tooltip.decoration;
      expect(decoration, isA<BoxDecoration>());

      final card = decoration! as BoxDecoration;
      expect(card.color, isNotNull, reason: 'a hint needs a background');
      expect(
        card.borderRadius,
        isNotNull,
        reason: 'a hint needs round corners',
      );
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

  test('the hint is a card of its own theme', () {
    Color? background(ThemeData theme) {
      final decoration = theme.tooltipTheme.decoration! as BoxDecoration;
      return decoration.color;
    }

    Color? letters(ThemeData theme) => theme.tooltipTheme.textStyle?.color;

    // The light theme has a paper hint, the dark theme a dark one: the hint
    // is a card of the theme it stands on.
    expect(
      background(CompactTheme.light)!.computeLuminance(),
      greaterThan(0.5),
      reason: 'the light theme has a light hint',
    );
    expect(
      background(CompactTheme.dark)!.computeLuminance(),
      lessThan(0.2),
      reason: 'the dark theme has a dark hint',
    );

    for (final theme in [CompactTheme.light, CompactTheme.dark]) {
      // The words keep the contrast of the card they sit on.
      expect(
        letters(theme)!.computeLuminance(),
        isNot(closeTo(background(theme)!.computeLuminance(), 0.2)),
        reason: 'the words have to be readable on the card',
      );
    }
  });

  test('the two themes have a hint of their own', () {
    Color card(ThemeData theme) =>
        (theme.tooltipTheme.decoration! as BoxDecoration).color!;

    Color rim(ThemeData theme) =>
        ((theme.tooltipTheme.decoration! as BoxDecoration).border! as Border)
            .top
            .color;

    // Two hints that only differ by a shade cannot be told apart, so a
    // reader who switches the theme would see no change at all.
    expect(
      card(CompactTheme.light),
      isNot(equals(card(CompactTheme.dark))),
      reason: 'the two themes need a card of their own',
    );
    expect(
      rim(CompactTheme.light),
      isNot(equals(rim(CompactTheme.dark))),
      reason: 'the two themes need a rim of their own',
    );

    // The card of the dark theme has to lift off the desk it stands on.
    final darkDesk = CompactTheme.dark.scaffoldBackgroundColor;
    expect(
      card(CompactTheme.dark).computeLuminance(),
      greaterThan(darkDesk.computeLuminance() * 2),
      reason: 'the hint has to be seen on the dark desk',
    );

    // The card of the light theme has to stand off the paper of the page.
    final lightDesk = CompactTheme.light.scaffoldBackgroundColor;
    expect(
      card(CompactTheme.light).computeLuminance(),
      lessThan(lightDesk.computeLuminance()),
      reason: 'the hint has to be seen on the paper of the page',
    );
  });

  testWidgets('a hint without words shows nothing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TuneTooltip(message: '   ', child: Text('body')),
        ),
      ),
    );

    expect(find.byType(RawTooltip), findsNothing);
    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('a hint with words says them', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TuneTooltip(message: 'Play', child: Text('body')),
        ),
      ),
    );

    expect(find.byType(RawTooltip), findsOneWidget);
    expect(
      tester.widget<RawTooltip>(find.byType(RawTooltip)).semanticsTooltip,
      'Play',
    );
  });

  testWidgets('the wide sidebar does not say the name of a page twice', (
    tester,
  ) async {
    await tester.pumpWidget(sidebar(compact: false));

    expect(find.byType(RawTooltip), findsNothing);
  });

  testWidgets('the narrow sidebar names the page on the pointer', (
    tester,
  ) async {
    await tester.pumpWidget(sidebar(compact: true));

    expect(find.byType(RawTooltip), findsNWidgets(5));
  });

  testWidgets('the hint follows the theme of the app', (tester) async {
    await tester.pumpWidget(_app(ThemeMode.light));
    await tester.pump();
    final mouse = await _putPointerOn(tester);

    final light = _paintedCard(tester);
    expect(light, isNotNull, reason: 'the hint has to paint a card');
    expect(
      light!.color,
      _cardOf(ThemeMode.light),
      reason: 'the hint has to take the card of the light theme',
    );

    await tester.pumpWidget(_app(ThemeMode.dark));
    await tester.pump();
    // The pointer moves, so the hint opens again in the new theme.
    await mouse.moveTo(
      tester.getCenter(find.text('body')) + const Offset(1, 0),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 200));

    final dark = _paintedCard(tester);
    expect(dark, isNotNull);
    expect(
      dark!.color,
      _cardOf(ThemeMode.dark),
      reason: 'the hint has to take the card of the dark theme',
    );
    expect(
      dark.color,
      isNot(light.color),
      reason: 'the two themes must not share one card',
    );
  });

  testWidgets('an open hint takes the theme that comes', (tester) async {
    await tester.pumpWidget(_app(ThemeMode.light));
    await tester.pump();
    await _putPointerOn(tester);

    final before = _paintedCard(tester);
    expect(before, isNotNull, reason: 'the hint has to be open');

    // The theme changes while the hint is on the screen. The theme of the
    // app moves over a moment, so the change is given the time it takes.
    await tester.pumpWidget(_app(ThemeMode.dark));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The hint stays on the screen and takes the card of the new theme.
    final after = _paintedCard(tester);
    expect(after, isNotNull, reason: 'the hint has to stay on the screen');
    expect(
      after!.color,
      _cardOf(ThemeMode.dark),
      reason: 'a hint on the screen has to take the new theme',
    );
    expect(
      after.color,
      isNot(before!.color),
      reason: 'the hint must not keep the card of the old theme',
    );
  });

  test('no widget writes a hint of its own', () {
    final offenders = <String>[];

    for (final file in _dartFiles('lib')) {
      if (file.path.endsWith('shared/ui/tune_tooltip.dart')) continue;

      final source = file.readAsStringSync();
      for (final match in RegExp(r'\bTooltip\(').allMatches(source)) {
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        offenders.add('${file.path}:$line');
      }

      // The widgets of the framework carry a hint of their own, and that
      // hint does not follow the theme while it is open. The hint of the app
      // goes through [TuneTooltip].
      for (final match in _frameworkHint.allMatches(source)) {
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        offenders.add('${file.path}:$line');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'a widget writes a hint of its own:\n${offenders.join('\n')}',
    );
  });
}

/// The widgets of the framework that carry a hint of their own.
///
/// The name of the widget may carry a kind of type and a builder, as in
/// `PopupMenuButton<String>(...)`.
final _frameworkHint = RegExp(
  r'\b(?:IconButton|PopupMenuButton)(?:<[^>]*>)?(?:\.\w+)?\s*'
  r'\((?:[^()]|\([^()]*\))*?\btooltip\s*:',
);

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

/// A page with a single hint on it, in the theme that is asked for.
///
/// The app names both themes and says which one it wants with [ThemeMode],
/// so the page does the same.
Widget _app(ThemeMode mode) {
  return MaterialApp(
    theme: CompactTheme.light,
    darkTheme: CompactTheme.dark,
    themeMode: mode,
    home: const Scaffold(
      body: Center(
        child: TuneTooltip(message: 'Play', child: Text('body')),
      ),
    ),
  );
}

/// The colour the card of the theme carries.
Color? _cardOf(ThemeMode mode) {
  final theme = mode == ThemeMode.dark ? CompactTheme.dark : CompactTheme.light;
  return (theme.tooltipTheme.decoration! as BoxDecoration).color;
}

/// The card the hint on the screen is painted with.
BoxDecoration? _paintedCard(WidgetTester tester) {
  for (final container in tester.widgetList<Container>(
    find.byType(Container),
  )) {
    final decoration = container.decoration;
    if (decoration is BoxDecoration &&
        decoration.border != null &&
        decoration.boxShadow != null) {
      return decoration;
    }
  }
  return null;
}

/// Puts the pointer on the hint and waits for it to open.
Future<TestGesture> _putPointerOn(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(mouse.removePointer);
  await mouse.addPointer(location: Offset.zero);
  await mouse.moveTo(tester.getCenter(find.text('body')));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 200));
  return mouse;
}

Iterable<File> _dartFiles(String directory) {
  return Directory(directory)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.contains('/l10n/app_localizations'));
}
