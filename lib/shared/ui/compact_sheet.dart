import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';

/// Shows a sheet at the bottom of the window.
///
/// The sheet takes only the room it needs, so the rest of the window belongs
/// to the barrier and a tap anywhere outside the sheet closes it. A sheet
/// that grows into the empty space above it swallows those taps instead, and
/// the reader is left with the narrow strips beside it as the only way out.
///
/// The room it needs is capped: a sheet whose content is taller than the
/// window scrolls inside the sheet instead of covering the window, so the
/// barrier stays reachable.
Future<T?> showCompactSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Align(
      alignment: Alignment.bottomCenter,
      // The sheet hugs its content instead of filling the window, which keeps
      // the barrier reachable everywhere above it.
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: CompactTokens.sheetWidth,
          maxHeight: (MediaQuery.sizeOf(context).height -
                  CompactTokens.sheetBarrierGap)
              .clamp(0.0, double.infinity),
        ),
        child: builder(context),
      ),
    ),
  );
}
