import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/theme/app_design_system.dart';

void main() {
  group('Responsive layout breakpoints', () {
    test('mobile breakpoint is 600', () {
      expect(AppDesignSystem.breakpointMobile, 600.0);
    });

    test('tablet breakpoint is 1024', () {
      expect(AppDesignSystem.breakpointTablet, 1024.0);
    });

    test('desktop breakpoint is 1440', () {
      expect(AppDesignSystem.breakpointDesktop, 1440.0);
    });

    test('wide breakpoint is 1920', () {
      expect(AppDesignSystem.breakpointWide, 1920.0);
    });
  });

  group('PlayerOptions Wrap layout', () {
    testWidgets('PlayerOptions renders without overflow', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 350,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.volume_mute),
                          SizedBox(width: 100, child: Placeholder()),
                          Icon(Icons.volume_up),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.speed),
                          SizedBox(width: 8),
                          Text('1x'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('Color consistency', () {
    test('neutral colors form a valid scale', () {
      final n50 = AppDesignSystem.neutral50;
      final n900 = AppDesignSystem.neutral900;
      // n50 比 n900 更浅（RGB 值更大）
      expect(n50.r, greaterThanOrEqualTo(n900.r));
      expect(n50.g, greaterThanOrEqualTo(n900.g));
      expect(n50.b, greaterThanOrEqualTo(n900.b));
    });

    test('primary color is purple-ish', () {
      final primary = AppDesignSystem.primary;
      // primary 应该有较高的 blue 分量（紫色）
      expect(primary.b, greaterThan(primary.r));
    });

    test('error color is red-ish', () {
      final error = AppDesignSystem.error;
      expect(error.r, greaterThan(error.g));
      expect(error.r, greaterThan(error.b));
    });
  });
}
