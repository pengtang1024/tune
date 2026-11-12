import 'package:flutter/widgets.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/config/platform_constants.dart';

/// The width class of the window.
///
/// The classes follow what the shell can still draw, not the names the
/// platforms give their devices: a narrow desktop window and a phone share a
/// width, and the navigation decides the rest.
enum LayoutClass {
  /// Below [LayoutBreakpoints.phoneMaxWidth]: a phone, or a window too narrow
  /// for the rail.
  phone,

  /// Between [LayoutBreakpoints.phoneMaxWidth] and
  /// [LayoutBreakpoints.railCompactMaxWidth]: the rail drops its labels.
  compact,

  /// The window the app opens with.
  regular,

  /// Wide enough for the three columns of the settings page.
  wide,
}

/// Where the navigation of the shell sits.
enum NavigationForm {
  /// The full rail with the names of the pages.
  rail,

  /// The rail with icons only.
  railCompact,

  /// A bar at the bottom of the window, for a touch screen.
  bottomBar,
}

/// The sizes at which the shell changes shape.
///
/// The numbers are part of the layout contract: the shell, the settings page
/// and the tests all read them here instead of carrying copies.
abstract final class LayoutBreakpoints {
  /// Below this width the navigation moves to the bottom on a touch screen.
  static const double phoneMaxWidth = 600;

  /// Below this width the rail drops its labels.
  ///
  /// The minimum window of the desktop is 760 wide, so a desktop window only
  /// ever sees this form on its narrowest sizes.
  static const double railCompactMaxWidth =
      CompactTokens.sidebarCompactBreakpoint;

  /// From this width the pages may use three columns.
  static const double wideMinWidth = 1180;

  /// The size of the window in mini mode.
  ///
  /// The bar holds the dock and nothing else, so its height follows the dock
  /// and its margins instead of the window of the normal mode. The numbers
  /// live in [PlatformConstants], which the window service reads without
  /// depending on this layer.
  static const Size miniWindowSize = Size(
    PlatformConstants.desktopMiniWindowWidth,
    PlatformConstants.desktopMiniWindowHeight,
  );
}

/// The layout the shell draws for a window of a given size.
class LayoutMetrics {
  const LayoutMetrics({
    required this.width,
    required this.height,
    required this.mobile,
    required this.layoutClass,
    required this.navigation,
  });

  /// The metrics of [size], for a build whose shell is [mobile] or not.
  ///
  /// The bottom bar belongs to the touch screen alone: a narrow desktop
  /// window keeps the rail, because a mouse reaches a rail faster than a bar
  /// and the window never becomes a phone by being made small.
  factory LayoutMetrics.of(Size size, {required bool mobile}) {
    final width = size.width;
    final layoutClass = switch (width) {
      < LayoutBreakpoints.phoneMaxWidth => LayoutClass.phone,
      < LayoutBreakpoints.railCompactMaxWidth => LayoutClass.compact,
      < LayoutBreakpoints.wideMinWidth => LayoutClass.regular,
      _ => LayoutClass.wide,
    };
    final navigation = switch (width) {
      _ when mobile && width < LayoutBreakpoints.railCompactMaxWidth =>
        NavigationForm.bottomBar,
      < LayoutBreakpoints.railCompactMaxWidth => NavigationForm.railCompact,
      _ => NavigationForm.rail,
    };
    return LayoutMetrics(
      width: width,
      height: size.height,
      mobile: mobile,
      layoutClass: layoutClass,
      navigation: navigation,
    );
  }

  final double width;
  final double height;

  /// Whether the build is a mobile one, whose shell uses the bottom bar.
  final bool mobile;

  final LayoutClass layoutClass;
  final NavigationForm navigation;

  bool get isPhone => layoutClass == LayoutClass.phone;

  bool get isWide => layoutClass == LayoutClass.wide;

  bool get usesBottomNavigation => navigation == NavigationForm.bottomBar;

  /// Whether the rail shows icons only, or is replaced by the bottom bar.
  bool get usesCompactNavigation => navigation != NavigationForm.rail;
}
