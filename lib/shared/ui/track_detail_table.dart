import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/shared/ui/meta_badge.dart';
import 'package:tune/shared/ui/track_detail_heading.dart';
import 'package:tune/shared/ui/track_detail_row.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// A group of lines under a name.
class TrackDetailSection {
  /// The name of the group. A group without a name follows the group before
  /// it, and the reader takes it for part of it.
  final String? heading;

  /// The lines of the group.
  final List<TrackDetailRow> rows;

  const TrackDetailSection({this.heading, required this.rows});
}

/// The facts of a track as a table of properties.
///
/// The names stand in a column of their own and the values in another one, so
/// the reader can run down the names and find the value they want without
/// reading every line. The names of the whole table share one column, so a
/// group that follows another one keeps the same left edge.
///
/// The values are written in the face of their kind: a path, a number and an
/// identifier in the machine face, the words of a person in the body face.
class TrackDetailTable extends StatelessWidget {
  final List<TrackDetailSection> sections;

  const TrackDetailTable({super.key, required this.sections});

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final section in sections)
        if (section.rows.isNotEmpty) ...section.rows,
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    final nameWidth = _nameWidth(context, rows);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final section in sections)
          if (section.rows.isNotEmpty) ...[
            if (section.heading != null) ...[
              const SizedBox(height: CompactTokens.space20),
              TrackDetailHeading(section.heading!),
              const SizedBox(height: CompactTokens.space10),
            ],
            for (final row in section.rows)
              TrackDetailLine(row: row, nameWidth: nameWidth),
          ],
      ],
    );
  }

  /// The width of the column of the names.
  ///
  /// The column is as wide as the longest name of the table, so the values
  /// all start at the same place and the names are never cut off.
  double _nameWidth(BuildContext context, List<TrackDetailRow> rows) {
    final style = Theme.of(context).textTheme.labelMedium;
    final scaler = MediaQuery.textScalerOf(context);
    var widest = 0.0;

    for (final row in rows) {
      final painter = TextPainter(
        text: TextSpan(text: row.label, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }

    // The icon and the room next to it stand in front of every name, and a
    // little room is left over so the longest name is never cut off.
    return widest +
        CompactTokens.icon16 +
        CompactTokens.space8 +
        CompactTokens.space4;
  }
}

/// One line of the table: the name of a thing and what it is.
class TrackDetailLine extends StatelessWidget {
  final TrackDetailRow row;

  /// The width of the column of the names, shared by the whole table.
  final double nameWidth;

  const TrackDetailLine({
    super.key,
    required this.row,
    required this.nameWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = factToneColor(row.tone, theme.colorScheme);

    return Padding(
      padding: const EdgeInsets.only(bottom: CompactTokens.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: nameWidth,
            child: Row(
              children: [
                Icon(row.icon, size: CompactTokens.icon16, color: tone),
                const SizedBox(width: CompactTokens.space8),
                Expanded(
                  child: Text(
                    row.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: CompactTokens.space12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectableText(
                    row.value,
                    style: _valueStyle(context),
                  ),
                ),
                if (row.copyHint != null) ...[
                  const SizedBox(width: CompactTokens.space8),
                  _CopyButton(hint: row.copyHint!, value: row.value),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The face of the value.
  ///
  /// A value that a machine wrote keeps the machine face, so the reader can
  /// tell the words of a person from the words of a program at a glance.
  TextStyle _valueStyle(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface;

    if (row.machine) {
      return CompactTypography.mono(color, size: CompactTypeScale.body);
    }

    return theme.textTheme.bodySmall?.copyWith(color: color) ??
        CompactTypography.sans(color, size: CompactTypeScale.body);
  }
}

/// The button that takes the value of a line away.
class _CopyButton extends StatelessWidget {
  final String hint;
  final String value;

  const _CopyButton({required this.hint, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TuneTooltip(
      message: hint,
      child: IconButton(
        onPressed: () => _copy(context),
        icon: const Icon(Icons.copy_rounded, size: CompactTokens.icon16),
        style: IconButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.loc.trackDetailsCopied),
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }
}
