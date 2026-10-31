import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/library/domain/library_filter.dart';
import 'package:tune/features/library/domain/library_sort.dart';
import 'package:tune/features/library/presentation/library_view_mode.dart';
import 'package:tune/features/library/presentation/library_view_switch.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// Value of the source filter that stands for "every source".
const String allSourcesFilterValue = '__all_sources__';

/// Search, source filter, result count, sort and view of the library.
///
/// The toolbar changes how the list is read; the whole-page actions (scan,
/// queue all) live behind the menu of the header.
class LibraryToolbar extends ConsumerWidget {
  final TextEditingController controller;
  final String query;
  final int filteredCount;
  final List<String> sources;
  final Map<String, SourceLabel> sourceLabels;
  final String? sourceFilter;
  final LibrarySort sort;
  final LibraryFilter filter;
  final LibraryViewMode view;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<String?> onSourceFilter;
  final ValueChanged<LibrarySort> onSort;
  final ValueChanged<LibraryViewMode> onViewChanged;
  final VoidCallback onFilter;

  const LibraryToolbar({
    super.key,
    required this.controller,
    required this.query,
    required this.filteredCount,
    required this.sources,
    required this.sourceLabels,
    required this.sourceFilter,
    required this.sort,
    required this.filter,
    required this.view,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onSourceFilter,
    required this.onSort,
    required this.onViewChanged,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SizedBox(
      height: CompactTokens.controlDefault,
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: CompactTokens.searchFieldMaxWidth,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: controller,
                    onChanged: onQueryChanged,
                    style: theme.textTheme.bodySmall,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainer,
                      hintText: context.loc.search,
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: CompactTokens.icon16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      suffixIcon: query.isEmpty
                          ? null
                          : TuneTooltip(
                              message: context.loc.libraryClearSearch,
                              child: IconButton(
                                onPressed: onClearQuery,
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: CompactTokens.icon14,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 28,
                                  height: 28,
                                ),
                              ),
                            ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: CompactTokens.space8,
                        vertical: CompactTokens.space8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: CompactTokens.borderRadius8,
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: CompactTokens.borderRadius8,
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: CompactTokens.borderRadius8,
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (sources.length > 1) ...[
            const SizedBox(width: CompactTokens.space8),
            _SourceFilter(
              sources: sources,
              sourceLabels: sourceLabels,
              sourceFilter: sourceFilter,
              onSourceFilter: onSourceFilter,
            ),
          ],
          const SizedBox(width: CompactTokens.space12),
          if (query.trim().isNotEmpty || sourceFilter != null) ...[
            Text(
              context.loc.libraryTrackCount(filteredCount),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: CompactTokens.space8),
          ],
          OutlinedButton.icon(
            key: const ValueKey('library-filter'),
            onPressed: onFilter,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, CompactTokens.controlDefault),
              padding: const EdgeInsets.symmetric(
                horizontal: CompactTokens.space8,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide(
                color: filter.isEmpty
                    ? theme.colorScheme.outlineVariant
                    : theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
              foregroundColor: filter.isEmpty
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.primary,
            ),
            icon: const Icon(
              Icons.filter_alt_outlined,
              size: CompactTokens.icon16,
            ),
            label: Text(
              filter.activeGroups == 0
                  ? context.loc.libraryFilter
                  : '${context.loc.libraryFilter} ${filter.activeGroups}',
            ),
          ),
          const SizedBox(width: CompactTokens.space8),
          _SortButton(sort: sort, onSort: onSort),
          const SizedBox(width: CompactTokens.space8),
          LibraryViewSwitch(view: view, onChanged: onViewChanged),
        ],
      ),
    );
  }
}

/// The button that says how the list is ordered and opens the other orders.
class _SortButton extends StatelessWidget {
  final LibrarySort sort;
  final ValueChanged<LibrarySort> onSort;

  const _SortButton({required this.sort, required this.onSort});

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

/// Chip that opens the source filter menu.
class _SourceFilter extends StatelessWidget {
  final List<String> sources;
  final Map<String, SourceLabel> sourceLabels;
  final String? sourceFilter;
  final ValueChanged<String?> onSourceFilter;

  const _SourceFilter({
    required this.sources,
    required this.sourceLabels,
    required this.sourceFilter,
    required this.onSourceFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = sourceFilter != null;
    final label = sourceFilter == null
        ? context.loc.libraryAllSources
        : (sourceLabels[sourceFilter]?.name ?? sourceFilter!);

    return TuneTooltip(
      message: active
          ? '${context.loc.libraryFilterSources} · $label'
          : context.loc.libraryFilterSources,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        initialValue: sourceFilter ?? allSourcesFilterValue,
        onSelected: (value) {
          onSourceFilter(value == allSourcesFilterValue ? null : value);
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: allSourcesFilterValue,
            height: 36,
            child: Text(context.loc.libraryAllSources),
          ),
          for (final sourceId in sources)
            PopupMenuItem<String>(
              value: sourceId,
              height: 36,
              child: Text(sourceLabels[sourceId]?.name ?? sourceId),
            ),
        ],
        child: Container(
          height: CompactTokens.controlDefault,
          padding: const EdgeInsets.symmetric(horizontal: CompactTokens.space8),
          decoration: BoxDecoration(
            color: active
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : theme.colorScheme.surfaceContainer,
            borderRadius: CompactTokens.borderRadius8,
            border: Border.all(
              color: active
                  ? theme.colorScheme.primary.withValues(alpha: 0.4)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: CompactTokens.icon16,
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: CompactTokens.space4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: CompactTokens.icon14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
