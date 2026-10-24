import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/hint_layer.dart';
import 'package:tune/shared/ui/hint_trigger.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// Guards the one hint layer of the app.
///
/// The layer owns the card: a trigger only says the words and the rectangle.
/// These tests hold the behaviour a reader notices: one card at a time, the
/// theme while it is open, a close on a click, a scroll or a window change,
/// and a long touch that stays long enough to be read.
void main() {
  testWidgets('one card at a time, and the idle tree holds none', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        body: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Probe(message: 'First', label: 'first'),
            _Probe(message: 'Second', label: 'second'),
          ],
        ),
      ),
    );

    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsNothing);

    final mouse = await _putPointerOn(tester, 'first');
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsNothing);

    await mouse.moveTo(tester.getCenter(find.text('second')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('a hover closes after the pointer leaves', (tester) async {
    await tester.pumpWidget(
      _app(
        body: const _Probe(message: 'First', label: 'first'),
      ),
    );

    final mouse = await _putPointerOn(tester, 'first');
    expect(find.text('First'), findsOneWidget);

    await mouse.moveTo(const Offset(4, 4));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('First'), findsOneWidget, reason: 'the exit has a delay');

    // One pump lets the exit timer fire and starts the fade; the next one
    // lets the card leave the screen.
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('First'), findsNothing);
  });

  testWidgets('an open card takes the theme that comes', (tester) async {
    const body = _Probe(message: 'First', label: 'first');
    await tester.pumpWidget(_app(body: body));
    await _putPointerOn(tester, 'first');

    final light = _paintedCard(tester);
    expect(light, isNotNull);
    expect(light!.color, _cardOf(ThemeMode.light));

    await tester.pumpWidget(_app(body: body, mode: ThemeMode.dark));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final dark = _paintedCard(tester);
    expect(dark, isNotNull, reason: 'the card stays open');
    expect(
      dark!.color,
      _cardOf(ThemeMode.dark),
      reason: 'a card on the screen takes the new theme',
    );
    expect(dark.color, isNot(light.color));
  });

  testWidgets('a click closes the card', (tester) async {
    await tester.pumpWidget(
      _app(
        body: const _Probe(message: 'First', label: 'first'),
      ),
    );
    await _putPointerOn(tester, 'first');
    expect(find.text('First'), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('First'), findsNothing);
  });

  testWidgets('a scroll closes the card', (tester) async {
    await tester.pumpWidget(
      _app(
        body: SizedBox(
          height: 180,
          child: ListView(
            children: const [
              _Probe(message: 'First', label: 'first'),
              SizedBox(height: 400),
            ],
          ),
        ),
      ),
    );
    await _putPointerOn(tester, 'first');
    expect(find.text('First'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -60));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('First'), findsNothing);
  });

  testWidgets('a long touch opens the card and keeps it after the finger', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        body: const _Probe(message: 'First', label: 'first'),
      ),
    );

    final touch = await tester.startGesture(
      tester.getCenter(find.text('first')),
      kind: PointerDeviceKind.touch,
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    expect(find.text('First'), findsOneWidget);

    await touch.up();
    await tester.pump();
    expect(
      find.text('First'),
      findsOneWidget,
      reason: 'a long touch leaves the card long enough to be read',
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('First'), findsNothing);
  });

  testWidgets('a trigger that leaves the tree takes its card away', (
    tester,
  ) async {
    var visible = true;
    await tester.pumpWidget(
      _app(
        body: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (visible) const _Probe(message: 'First', label: 'first'),
                TextButton(
                  onPressed: () => setState(() => visible = false),
                  child: const Text('remove'),
                ),
              ],
            );
          },
        ),
      ),
    );
    await _putPointerOn(tester, 'first');
    expect(find.text('First'), findsOneWidget);

    await tester.tap(find.text('remove'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(HintTrigger), findsNothing);
    expect(find.text('First'), findsNothing);
  });

  testWidgets('a hint without words is no trigger', (tester) async {
    await tester.pumpWidget(
      _app(
        body: const TuneTooltip(message: '   ', child: Text('body')),
      ),
    );

    expect(find.byType(HintTrigger), findsNothing);
    expect(find.text('body'), findsOneWidget);
  });
}

class _Probe extends StatelessWidget {
  final String message;
  final String label;

  const _Probe({required this.message, required this.label});

  @override
  Widget build(BuildContext context) {
    return TuneTooltip(
      message: message,
      label: label,
      child: SizedBox(
        width: 120,
        height: 40,
        child: Center(child: Text(label)),
      ),
    );
  }
}

Widget _app({Widget? body, ThemeMode mode = ThemeMode.light}) {
  return MaterialApp(
    theme: CompactTheme.light,
    darkTheme: CompactTheme.dark,
    themeMode: mode,
    locale: const Locale('zh', 'CN'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) =>
        HintLayer(child: child ?? const SizedBox.shrink()),
    home: Scaffold(body: Center(child: body ?? const SizedBox.shrink())),
  );
}

Future<TestGesture> _putPointerOn(WidgetTester tester, String label) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(mouse.removePointer);
  await mouse.addPointer(location: Offset.zero);
  await mouse.moveTo(tester.getCenter(find.text(label)));
  await tester.pump(const Duration(milliseconds: 500));
  return mouse;
}

Color? _cardOf(ThemeMode mode) {
  final theme = mode == ThemeMode.dark ? CompactTheme.dark : CompactTheme.light;
  return (theme.tooltipTheme.decoration! as BoxDecoration).color;
}

BoxDecoration? _paintedCard(WidgetTester tester) {
  final text = find.text('First');
  if (text.evaluate().isEmpty) return null;
  for (final container in tester.widgetList<Container>(
    find.ancestor(of: text, matching: find.byType(Container)),
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
