import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/library_sort.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The button that says how the list is ordered and opens the other orders.
class LibrarySortButton extends StatelessWidget {
  final LibrarySort sort;
  final ValueChanged<LibrarySort> onSort;

  /// Drops the name of the order and keeps the arrow, for a row that has no
  /// room for it. The menu still names every order.
  final bool compact;

  const LibrarySortButton({
    super.key,
    required this.sort,
    required this.onSort,
    this.compact = false,
  });

  static String labelOf(BuildContext context, LibrarySort sort) {
    final strings = context.loc;
    return switch (sort.field) {
      LibrarySortField.title => strings.librarySortTitle,
      LibrarySortField.addedAt => strings.librarySortRecent,
      LibrarySortField.artist => strings.librarySortArtist,
      LibrarySortField.album => strings.librarySortAlbum,
      LibrarySortField.duration => strings.librarySortDuration,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TuneTooltip(
      message: context.loc.librarySortTooltip,
      child: PopupMenuButton<LibrarySortField>(
        key: const ValueKey('library-sort'),
        padding: EdgeInsets.zero,
        onSelected: (field) => onSort(sort.then(field)),
        itemBuilder: (context) => [
          for (final field in LibrarySortField.values)
            PopupMenuItem<LibrarySortField>(
              value: field,
              height: 36,
              child: Row(
                children: [
                  Icon(
                    field == sort.field
                        ? (sort.ascending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded)
                        : Icons.remove_rounded,
                    size: CompactTokens.icon14,
                    color: field == sort.field
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                  ),
                  const SizedBox(width: CompactTokens.space8),
                  Text(
                    labelOf(
                      context,
                      LibrarySort(
                        field: field,
                        ascending: field != LibrarySortField.addedAt,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        child: Container(
          height: CompactTokens.controlDefault,
          padding: const EdgeInsets.symmetric(horizontal: CompactTokens.space8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: CompactTokens.borderRadius8,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (compact)
                Icon(
                  Icons.swap_vert_rounded,
                  size: CompactTokens.icon16,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              else
                Text(
                  labelOf(context, sort),
                  style: CompactTypography.mono(
                    theme.colorScheme.onSurfaceVariant,
                    size: CompactTypeScale.mark,
                  ),
                ),
              const SizedBox(width: CompactTokens.space4),
              Icon(
                sort.ascending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: CompactTokens.icon14,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
