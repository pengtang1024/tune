import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/layout/layout_metrics.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/config/platform_constants.dart';

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

  test('a window narrower than a phone takes the bottom bar, whatever it runs on', () {
    // The desktop window stops at 560 wide, inside this band, so the
    // narrowest window is the phone form instead of a squeezed rail.
    expect(
      LayoutBreakpoints.phoneMaxWidth,
      greaterThan(PlatformConstants.desktopWindowMinWidth),
    );
    expect(metrics(420).navigation, NavigationForm.bottomBar);
    expect(metrics(420).usesBottomNavigation, isTrue);
    expect(metrics(560).navigation, NavigationForm.bottomBar);
    expect(metrics(599).navigation, NavigationForm.bottomBar);
    expect(metrics(599).isPhone, isTrue);
  });

  test('the rail keeps its labels between the phone and the wide layout', () {
    // A desktop window between 600 and 799 still shows the rail, with icons
    // only, because it has the height of a desktop and a mouse to reach it.
    expect(metrics(600).navigation, NavigationForm.railCompact);
    expect(metrics(760).navigation, NavigationForm.railCompact);
    expect(metrics(799).usesCompactNavigation, isTrue);
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

  test('the mini window is exactly the dock', () {
    // The bar is the whole window: no title bar above it, and the progress
    // line is drawn inside this height rather than added to it.
    expect(
      LayoutBreakpoints.miniWindowSize.height,
      CompactTokens.dockHeight,
    );
    expect(
      LayoutBreakpoints.miniWindowSize.width,
      lessThan(LayoutBreakpoints.phoneMaxWidth),
    );
  });
}
