import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';

/// Shows a sheet at the bottom of the window.
///
/// The sheet takes only the room it needs, so the rest of the window belongs
/// to the barrier and a tap anywhere outside the sheet closes it. A sheet
/// that grows into the empty space above it swallows those taps instead, and
/// the reader is left with the narrow strips beside it as the only way out.
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
        constraints: const BoxConstraints(maxWidth: CompactTokens.sheetWidth),
        child: builder(context),
      ),
    ),
  );
}
