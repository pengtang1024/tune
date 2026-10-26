import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/shared/ui/horizontal_shelf.dart';

void main() {
  Widget shelf({int itemCount = 10, double width = 420}) {
    return MaterialApp(
      theme: CompactTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: 140,
            child: HorizontalShelf(
              itemCount: itemCount,
              spacing: 8,
              previousLabel: 'Previous',
              nextLabel: 'Next',
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 100,
                  height: 100,
                  child: Text('item $index'),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  final back = find.byKey(const ValueKey('horizontal-shelf-back'));
  final forward = find.byKey(const ValueKey('horizontal-shelf-forward'));

  testWidgets('a row that fits keeps no arrows', (tester) async {
    await tester.pumpWidget(shelf(itemCount: 3));
    await tester.pumpAndSettle();

    expect(back, findsNothing);
    expect(forward, findsNothing);
  });

  testWidgets('a row that does not fit offers the way forward', (tester) async {
    await tester.pumpWidget(shelf());
    await tester.pumpAndSettle();

    expect(back, findsNothing);
    expect(forward, findsOneWidget);
    expect(find.byType(Scrollbar), findsOneWidget);
  });

  testWidgets('a wider row drops the arrows it no longer needs', (
    tester,
  ) async {
    await tester.pumpWidget(shelf(itemCount: 5, width: 420));
    await tester.pumpAndSettle();
    expect(forward, findsOneWidget);

    await tester.pumpWidget(shelf(itemCount: 5, width: 900));
    await tester.pumpAndSettle();
    expect(back, findsNothing);
    expect(forward, findsNothing);
  });

  testWidgets('the forward arrow moves one page and then gives way back', (
    tester,
  ) async {
    await tester.pumpWidget(shelf());
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );

    await tester.tap(forward);
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
    expect(back, findsOneWidget);

    await tester.tap(forward);
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, scrollable.position.maxScrollExtent);
    expect(forward, findsNothing);

    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(
      scrollable.position.pixels,
      lessThan(scrollable.position.maxScrollExtent),
    );
    expect(forward, findsOneWidget);
  });

  testWidgets('the arrow can be reached and pressed from the keyboard', (
    tester,
  ) async {
    await tester.pumpWidget(shelf());
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(0));
  });
}
