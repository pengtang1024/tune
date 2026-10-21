import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/shared/ui/meta_badge.dart';
import 'package:tune/shared/ui/track_detail_columns.dart';
import 'package:tune/shared/ui/track_detail_heading.dart';
import 'package:tune/shared/ui/track_detail_row.dart';

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
/// The table is exactly as wide as its words: the columns are measured from
/// the words that go in them, and the panel that holds the table is as wide
/// as the table. A table that reaches for the width of the window leaves a
/// stretch of nothing beside the values, and that emptiness is what makes a
/// panel look thin.
class TrackDetailTable extends StatelessWidget {
  final List<TrackDetailSection> sections;

  /// The widths of the two columns, shared by every group of the table.
  final TrackDetailColumns columns;

  const TrackDetailTable({
    super.key,
    required this.sections,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final section in sections)
        if (section.rows.isNotEmpty) ...section.rows,
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final section in sections)
          if (section.rows.isNotEmpty) ...[
            if (section.heading != null) ...[
              const SizedBox(height: CompactTokens.space14),
              TrackDetailHeading(section.heading!),
              const SizedBox(height: CompactTokens.space8),
            ],
            for (final row in section.rows)
              TrackDetailLine(row: row, columns: columns),
          ],
      ],
    );
  }
}

/// One line of the table: the name of a thing and what it is.
class TrackDetailLine extends StatelessWidget {
  final TrackDetailRow row;

  /// The widths of the two columns, shared by the whole table.
  final TrackDetailColumns columns;

  const TrackDetailLine({
    super.key,
    required this.row,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = factToneColor(row.tone, theme.colorScheme);

    return Padding(
      padding: const EdgeInsets.only(bottom: CompactTokens.space6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: columns.name,
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
          SizedBox(width: columns.value, child: _ValueCell(row: row)),
        ],
      ),
    );
  }
}

/// The value of a line, and the button that takes it away.
class _ValueCell extends StatelessWidget {
  final TrackDetailRow row;

  const _ValueCell({required this.row});

  @override
  Widget build(BuildContext context) {
    // A value too long for a line is not written out: the chip carries it,
    // and the reader reads it where the pointer rests.
    if (row.inChip) {
      return Align(
        alignment: Alignment.centerLeft,
        child: CopyChip(address: row.value, hint: row.copyHint ?? row.label),
      );
    }

    // The value is written out as plain text and not as selectable text: a
    // selectable text keeps a scroll room of forty pixels around itself and
    // writes its words in what is left, so the column would have to be that
    // much wider than the words need and the panel would grow with it.
    return Text(
      row.value,
      style: trackDetailValueStyle(context, row),
    );
  }
}
