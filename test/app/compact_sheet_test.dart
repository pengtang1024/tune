import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/shared/ui/compact_sheet.dart';

/// A sheet takes the room it needs and never the whole window.
///
/// The barrier behind a sheet is what closes it when the reader taps outside
/// of it, so a sheet that reaches the top of the window takes that way of
/// closing it away.
void main() {
  Future<void> open(WidgetTester tester, Widget sheet) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showCompactSheet<void>(context, (_) => sheet),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a short sheet takes only the room it needs', (tester) async {
    await open(tester, const SizedBox(height: 120, width: 300));

    final sheet = tester.getRect(find.byType(BottomSheet));
    expect(sheet.height, 120);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tall sheet leaves a strip of the barrier above it', (
    tester,
  ) async {
    await open(tester, const SizedBox(height: 4000, width: 300));

    final sheet = tester.getRect(find.byType(BottomSheet));
    // The sheet stops before the top of the window, so the barrier above it
    // can still be tapped.
    expect(sheet.top, greaterThanOrEqualTo(CompactTokens.sheetBarrierGap));
    expect(
      sheet.height,
      lessThanOrEqualTo(600 - CompactTokens.sheetBarrierGap + 0.01),
    );
    expect(tester.takeException(), isNull);
  });
}
