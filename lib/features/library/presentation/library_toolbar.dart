import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/library_filter.dart';
import 'package:tune/domain/models/library_sort.dart';
import 'package:tune/features/library/presentation/library_search_field.dart';
import 'package:tune/features/library/presentation/library_sort_button.dart';
import 'package:tune/features/library/presentation/library_source_filter.dart';
import 'package:tune/features/library/presentation/library_view_mode.dart';
import 'package:tune/features/library/presentation/library_view_switch.dart';

/// Search, source filter, result count, sort and view of the library.
///
/// The toolbar changes how the list is read; the whole-page actions (scan,
/// queue all) live behind the menu of the header.
class LibraryToolbar extends ConsumerWidget {
  final TextEditingController controller;

  /// The keyboard focus of the search field.
  ///
  /// The app-wide shortcut that focuses the field lives above the page and
  /// asks this node for the focus.
  final FocusNode? focusNode;

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

  /// Below this width the search field and the controls cannot share a row:
  /// the field ends up narrower than its own prefix icon and the row
  /// overflows. A phone gets two rows instead.
  static const double _twoRowBreakpoint = 560;

  const LibraryToolbar({
    super.key,
    required this.controller,
    this.focusNode,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _twoRowBreakpoint) {
          return SizedBox(
            height: CompactTokens.controlDefault,
            child: Row(
              children: [
                Expanded(child: _searchField()),
                ..._sourceAndCount(context),
                const SizedBox(width: CompactTokens.space12),
                ..._buttons(context, compact: false),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: CompactTokens.controlDefault,
              child: _searchField(),
            ),
            const SizedBox(height: CompactTokens.space8),
            SizedBox(
              height: CompactTokens.controlDefault,
              child: Row(
                children: [
                  ..._sourceAndCount(context),
                  const Spacer(),
                  ..._buttons(context, compact: true),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _searchField() {
    return LibrarySearchField(
      controller: controller,
      focusNode: focusNode,
      query: query,
      onChanged: onQueryChanged,
      onClear: onClearQuery,
    );
  }

  List<Widget> _sourceAndCount(BuildContext context) {
    final theme = Theme.of(context);
    final showCount = query.trim().isNotEmpty || sourceFilter != null;
    return [
      if (sources.length > 1)
        LibrarySourceFilter(
          sources: sources,
          sourceLabels: sourceLabels,
          sourceFilter: sourceFilter,
          onSourceFilter: onSourceFilter,
        ),
      if (showCount) ...[
        if (sources.length > 1) const SizedBox(width: CompactTokens.space8),
        Text(
          context.loc.libraryTrackCount(filteredCount),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ];
  }

  List<Widget> _buttons(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    return [
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
      LibrarySortButton(sort: sort, onSort: onSort, compact: compact),
      const SizedBox(width: CompactTokens.space8),
      LibraryViewSwitch(view: view, onChanged: onViewChanged),
    ];
  }
}
