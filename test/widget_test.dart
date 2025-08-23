import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/main.dart';

void main() {
  testWidgets('Tune app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        child: TuneApp(),
      ),
    );

    // Verify that the app loads without errors.
    expect(find.byType(Scaffold), findsWidgets);
    
    // Verify that we can find some common UI elements
    expect(find.byType(AppBar), findsOneWidget);
  });
}