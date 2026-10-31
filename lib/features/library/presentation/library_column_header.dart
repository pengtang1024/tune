import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/library/domain/library_sort.dart';
import 'package:tune/features/library/presentation/library_row_metrics.dart';

/// The header of the library table.
///
/// It shares [LibraryRowMetrics] with the rows, so a column disappears from
/// the header at the same width it disappears from the rows. The columns
/// are buttons: a click sorts by that column, a second click flips it.
class LibraryColumnHeader extends StatelessWidget {
  final LibraryRowMetrics metrics;
  final LibrarySort sort;
  final ValueChanged<LibrarySortField> onSort;

  const LibraryColumnHeader({
    super.key,
    required this.metrics,
    required this.sort,
    required this.onSort,
  });

  static const double _addedWidth = 64;
  static const double _tailWidth = 102;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = CompactTypography.mono(
      theme.colorScheme.onSurfaceVariant,
      size: CompactTypeScale.mark,
    );

    return SizedBox(
      height: 26,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: CompactTokens.space8),
        child: Row(
          children: [
            const SizedBox(
              width:
                  CompactTokens.positionColumnWidth +
                  CompactTokens.space8 +
                  CompactTokens.libraryArtwork +
                  CompactTokens.space10,
            ),
            Expanded(
              flex: 5,
              child: _column(
                context,
                context.loc.libraryColumnTitle,
                LibrarySortField.title,
                style,
              ),
            ),
            if (metrics.showArtist)
              Expanded(
                flex: 3,
                child: _column(
                  context,
                  context.loc.libraryColumnArtist,
                  LibrarySortField.artist,
                  style,
                ),
              ),
            if (metrics.showAlbum)
              Expanded(
                flex: 3,
                child: _column(
                  context,
                  context.loc.libraryColumnAlbum,
                  LibrarySortField.album,
                  style,
                ),
              ),
            if (metrics.showAdded)
              SizedBox(
                width: _addedWidth,
                child: _column(
                  context,
                  context.loc.libraryColumnAdded,
                  LibrarySortField.addedAt,
                  style,
                  alignEnd: true,
                ),
              ),
            SizedBox(
              width: _tailWidth,
              child: _column(
                context,
                context.loc.libraryColumnDuration,
                LibrarySortField.duration,
                style,
                alignEnd: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _column(
    BuildContext context,
    String label,
    LibrarySortField field,
    TextStyle? style, {
    bool alignEnd = false,
  }) {
    final active = sort.field == field;
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: active
          ? '$label, ${sort.ascending ? 'ascending' : 'descending'}'
          : label,
      child: InkWell(
        onTap: () => onSort(field),
        borderRadius: CompactTokens.borderRadius6,
        child: Align(
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style?.copyWith(
                    color: active
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (active) ...[
                const SizedBox(width: 2),
                Icon(
                  sort.ascending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: CompactTokens.icon14,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
