import 'package:flutter/material.dart';

/// Small, explicit token set for the compact desktop shell.
///
/// The legacy [AppDesignSystem] remains available for the old UI while it is
/// being removed. New code should depend on this file and on [Theme.of] instead
/// of reaching into the legacy token surface.
abstract final class CompactTokens {
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  static const double radius4 = 4;
  static const double radius6 = 6;
  static const double radius8 = 8;
  static const double radius12 = 12;

  static const double icon14 = 14;
  static const double icon16 = 16;
  static const double icon18 = 18;
  static const double icon20 = 20;
  static const double icon24 = 24;
  static const double icon28 = 28;

  static const double headerHeight = 44;
  static const double tabsHeight = 44;
  static const double rowHeight = 52;
  static const double controlSmall = 32;
  static const double controlMedium = 40;
  static const double controlLarge = 56;
  static const double inputHeight = 36;

  static const double playerPaneMinWidth = 312;
  static const double playerPaneMaxWidth = 360;

  static const EdgeInsets pagePadding = EdgeInsets.all(space16);
  static const EdgeInsets pagePaddingCompact = EdgeInsets.all(space12);

  static const BorderRadius borderRadius6 = BorderRadius.all(
    Radius.circular(radius6),
  );
  static const BorderRadius borderRadius8 = BorderRadius.all(
    Radius.circular(radius8),
  );
  static const BorderRadius borderRadius12 = BorderRadius.all(
    Radius.circular(radius12),
  );

  static const Duration fastMotion = Duration(milliseconds: 120);
  static const Duration standardMotion = Duration(milliseconds: 180);
}
