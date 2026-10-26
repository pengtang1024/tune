import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/shared/ui/dense_icon_action.dart';
import 'package:tune/shared/ui/hint_layer.dart';
import 'package:tune/shared/ui/icon_glyph.dart';

/// Guards the action of a dense row.
///
/// The primitive exists to keep the parts a reader uses — ink, focus,
/// keyboard and semantics — while dropping the box of a page button. The
/// budget guards the reason it exists at all.
void main() {
  testWidgets('a dense action taps, focuses and activates with the keyboard', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        DenseIconAction(
          icon: Icons.add_rounded,
          tooltip: 'Add',
          onPressed: () => taps++,
        ),
      ),
    );

    await tester.tap(_mark(Icons.add_rounded));
    expect(taps, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus,
      isNotNull,
      reason: 'the action takes the keyboard',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 2, reason: 'Enter activates the action');

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(taps, 3, reason: 'Space activates the action');
  });

  testWidgets('a dense action says it is a button and when it is off', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _app(
          const DenseIconAction(
            icon: Icons.add_rounded,
            tooltip: 'Add',
            onPressed: null,
          ),
        ),
      );

      final button = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.button == true,
      );
      final node = tester.getSemantics(button);
      final flags = node.flagsCollection;
      expect(flags.isButton, isTrue);
      expect(
        flags.isEnabled,
        Tristate.isFalse,
        reason: 'an action that is off says so, rather than saying nothing',
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('a dense action stays inside the budget of a row action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const DenseIconAction(
          icon: Icons.add_rounded,
          tooltip: 'Add',
          onPressed: _noop,
        ),
      ),
    );

    // The body is the part this widget owns: the ink, the box and the mark.
    // The hint trigger above it is counted with the hints of the row.
    final body = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.button == true,
    );
    final bodyElements = _count(tester.element(body));
    expect(
      bodyElements,
      lessThanOrEqualTo(20),
      reason: 'the body of a dense action stays a primitive of a row',
    );

    // A row pays for the whole action, hint included. The number guards the
    // promise that three actions do not turn a row into a page.
    final elements = _count(tester.element(find.byType(DenseIconAction)));
    expect(
      elements,
      lessThanOrEqualTo(25),
      reason: 'a dense action with its hint stays small enough for a row',
    );
  });
}

Finder _mark(IconData icon) {
  return find.byWidgetPredicate(
    (widget) => widget is IconGlyph && widget.icon == icon,
  );
}

Widget _app(Widget action) {
  return MaterialApp(
    theme: CompactTheme.light,
    builder: (context, child) =>
        HintLayer(child: child ?? const SizedBox.shrink()),
    home: Scaffold(
      body: Center(child: Material(child: action)),
    ),
  );
}

int _count(Element element) {
  var total = 1;
  element.visitChildren((child) {
    total += _count(child);
  });
  return total;
}

void _noop() {}
