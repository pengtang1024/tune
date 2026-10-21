import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/shared/ui/track_detail_row.dart';
import 'package:tune/shared/utils/text_width.dart';

/// The two columns of a table of facts.
///
/// The names stand in a column of their own and the values in another one, so
/// the reader can run down the names and find the value they want without
/// reading every line.
///
/// The columns are measured from the words that go in them, so the table is
/// exactly as wide as the words need and not a pixel more: a table that
/// reaches for the width of the window leaves a stretch of nothing beside the
/// values, and that emptiness is what makes a panel look thin.
class TrackDetailColumns {
  /// The width of the column of the names.
  final double name;

  /// The width of the column of the values.
  final double value;

  const TrackDetailColumns({required this.name, required this.value});

  /// The columns a table of these rows needs.
  ///
  /// [maxWidth] is the room the whole table may take; the column of the
  /// values gives way when the words in it do not fit.
  factory TrackDetailColumns.of(
    BuildContext context,
    List<TrackDetailRow> rows, {
    double maxWidth = double.infinity,
  }) {
    final nameWidth = _nameWidth(context, rows);
    final room = math.max(
      0.0,
      maxWidth - nameWidth - CompactTokens.space12,
    );

    return TrackDetailColumns(
      name: nameWidth,
      value: _valueWidth(context, rows, room),
    );
  }

  /// The width of the column of the names.
  ///
  /// The column is as wide as the longest name of the table, so the values
  /// all start at the same place and the names are never cut off.
  static double _nameWidth(BuildContext context, List<TrackDetailRow> rows) {
    final style = Theme.of(context).textTheme.labelMedium;
    var widest = 0.0;

    for (final row in rows) {
      widest = math.max(
        widest,
        measureTextWidth(context, row.label, style),
      );
    }

    // The icon and the room next to it stand in front of every name.
    return widest +
        CompactTokens.icon16 +
        CompactTokens.space8 +
        CompactTokens.space4;
  }

  /// The width of the column of the values.
  static double _valueWidth(
    BuildContext context,
    List<TrackDetailRow> rows,
    double room,
  ) {
    var widest = CompactTokens.chipBox;

    for (final row in rows) {
      // A value that a chip carries is not written out, so it does not make
      // the column wider than the chip itself.
      if (row.inChip) continue;

      widest = math.max(
        widest,
        measureTextWidth(
          context,
          row.value,
          trackDetailValueStyle(context, row),
        ),
      );
    }

    return math.min(widest, room);
  }
}

/// The face of a value of the table.
///
/// A value that a machine wrote keeps the machine face, so the reader can
/// tell the words of a person from the words of a program at a glance.
TextStyle trackDetailValueStyle(BuildContext context, TrackDetailRow row) {
  final theme = Theme.of(context);
  final color = theme.colorScheme.onSurface;

  if (row.machine) {
    return CompactTypography.mono(color, size: CompactTypeScale.body);
  }

  return theme.textTheme.bodySmall?.copyWith(color: color) ??
      CompactTypography.sans(color, size: CompactTypeScale.body);
}
