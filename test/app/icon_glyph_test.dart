import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/shared/ui/icon_glyph.dart';

/// Guards the mark that stands in for [Icon] in a dense row.
///
/// The mark keeps the glyph and the square the framework icon would have
/// given it; this test says so, and says the private-use character never
/// reaches the screen reader.
void main() {
  testWidgets('a glyph keeps the square of the icon it replaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: IconGlyph(Icons.album_rounded, size: 24, boxed: true),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(IconGlyph)),
      const Size.square(24),
      reason: 'the mark occupies the same square as Icon',
    );
  });

  testWidgets('a glyph has the square of its font without a box', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: IconGlyph(Icons.album_rounded, size: 24)),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(IconGlyph)),
      const Size.square(24),
      reason: 'an icon font has one em of advance; the mark needs no box',
    );
  });

  testWidgets('a glyph says nothing to the screen reader', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: IconGlyph(Icons.album_rounded, size: 24)),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(
          String.fromCharCode(Icons.album_rounded.codePoint),
        ),
        findsNothing,
        reason: 'a mark is decoration; the control around it carries the name',
      );
    } finally {
      semantics.dispose();
    }
  });
}
