import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/layout/layout_metrics.dart';
import 'package:tune/app/theme/compact_tokens.dart';

void main() {
  LayoutMetrics metrics(double width, {bool mobile = false}) {
    return LayoutMetrics.of(Size(width, 720), mobile: mobile);
  }

  test('widths fall into the four classes at their edges', () {
    expect(metrics(599).layoutClass, LayoutClass.phone);
    expect(metrics(600).layoutClass, LayoutClass.compact);
    expect(metrics(799).layoutClass, LayoutClass.compact);
    expect(metrics(800).layoutClass, LayoutClass.regular);
    expect(metrics(1179).layoutClass, LayoutClass.regular);
    expect(metrics(1180).layoutClass, LayoutClass.wide);
  });

  test('the desktop rail drops its labels below the breakpoint', () {
    expect(metrics(760).navigation, NavigationForm.railCompact);
    expect(metrics(799).navigation, NavigationForm.railCompact);
    expect(metrics(800).navigation, NavigationForm.rail);
    expect(metrics(1180).navigation, NavigationForm.rail);
  });

  test('a narrow desktop window keeps the rail instead of a bottom bar', () {
    expect(metrics(420).navigation, NavigationForm.railCompact);
    expect(metrics(420).usesBottomNavigation, isFalse);
    expect(metrics(599).usesCompactNavigation, isTrue);
  });

  test('a touch build moves the navigation to the bottom', () {
    expect(metrics(420, mobile: true).navigation, NavigationForm.bottomBar);
    expect(metrics(599, mobile: true).usesBottomNavigation, isTrue);
    expect(metrics(600, mobile: true).navigation, NavigationForm.bottomBar);
    expect(metrics(800, mobile: true).navigation, NavigationForm.rail);
  });

  test('the rail breakpoint is the one the shell always used', () {
    expect(
      LayoutBreakpoints.railCompactMaxWidth,
      CompactTokens.sidebarCompactBreakpoint,
    );
  });

  test('the mini window keeps room for the dock', () {
    expect(
      LayoutBreakpoints.miniWindowSize.height,
      greaterThan(CompactTokens.dockHeight),
    );
    expect(
      LayoutBreakpoints.miniWindowSize.width,
      lessThan(LayoutBreakpoints.phoneMaxWidth),
    );
  });
}
