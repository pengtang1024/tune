import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/ui/theme/app_design_system.dart';

void main() {
  group('AppDesignSystem tokens', () {
    test('primary color is defined', () {
      expect(AppDesignSystem.primary, isNotNull);
    });

    test('gradient definitions are constant', () {
      // playerGradientDark 和 playerGradientLight 应该存在
      expect(AppDesignSystem.playerGradientDark, isA<LinearGradient>());
      expect(AppDesignSystem.playerGradientLight, isA<LinearGradient>());
      expect(AppDesignSystem.backgroundGradientDark, isA<LinearGradient>());
      expect(AppDesignSystem.backgroundGradientLight, isA<LinearGradient>());
    });

    test('player gradients have 3 color stops', () {
      expect(AppDesignSystem.playerGradientDark.colors.length, 3);
      expect(AppDesignSystem.playerGradientLight.colors.length, 3);
    });

    test('spacing tokens are positive', () {
      expect(AppDesignSystem.spacing8, 8.0);
      expect(AppDesignSystem.spacing16, 16.0);
      expect(AppDesignSystem.spacing24, 24.0);
    });

    test('borderRadius tokens are defined', () {
      expect(AppDesignSystem.borderRadius8, BorderRadius.circular(8));
      expect(AppDesignSystem.borderRadius16, BorderRadius.circular(16));
    });

    test('breakpoints are ordered correctly', () {
      expect(AppDesignSystem.breakpointMobile, lessThan(AppDesignSystem.breakpointTablet));
      expect(AppDesignSystem.breakpointTablet, lessThan(AppDesignSystem.breakpointDesktop));
      expect(AppDesignSystem.breakpointDesktop, lessThan(AppDesignSystem.breakpointWide));
    });

    test('fontFamilyPrimary is empty (platform default)', () {
      expect(AppDesignSystem.fontFamilyPrimary, isEmpty);
    });

    test('fontFamilySecondary is JetBrains Mono', () {
      expect(AppDesignSystem.fontFamilySecondary, 'JetBrains Mono');
    });

    test('duration tokens are positive', () {
      expect(AppDesignSystem.duration200.inMilliseconds, 200);
      expect(AppDesignSystem.duration300.inMilliseconds, 300);
      expect(AppDesignSystem.duration400.inMilliseconds, 400);
    });
  });
}
