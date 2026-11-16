import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/library_filter.dart';
import 'package:tune/domain/models/library_sort.dart';
import 'package:tune/features/library/presentation/library_count_label.dart';
import 'package:tune/features/library/presentation/library_search_field.dart';
import 'package:tune/features/library/presentation/library_sort_button.dart';
import 'package:tune/features/library/presentation/library_source_filter.dart';

/// Search, source filter, result count and sort of the library.
///
/// The toolbar changes what the list holds; the whole-page actions (scan,
/// queue all) live behind the menu of the header. The list itself says what
/// it is — a group row or a track row — so there is no view switch here.
///
/// A wide window keeps the search field in the row, with the count beside it.
/// A narrow window ([compact]) leaves the search to the header's icon and the
/// count to the header, and spends its one row on the source, the filter and
/// the order — so the page keeps three rows of chrome instead of five.
class LibraryToolbar extends ConsumerWidget {
  final TextEditingController controller;

  /// The keyboard focus of the search field.
  ///
  /// The app-wide shortcut that focuses the field lives above the page and
  /// asks this node for the focus.
  final FocusNode? focusNode;

  final String query;

  /// How many tracks the word, the scope and the filter match.
  final int count;

  /// How many matching tracks the list leaves out for having no duration.
  final int hiddenMissingDuration;

  /// The content the page is scoped to, when it names one kind; the count
  /// then counts shows, chapters or stations instead of songs.
  final ContentKind? kind;

  final List<String> sources;
  final Map<String, SourceLabel> sourceLabels;
  final String? sourceFilter;
  final LibrarySort sort;
  final LibraryFilter filter;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<String?> onSourceFilter;
  final ValueChanged<LibrarySort> onSort;
  final VoidCallback onFilter;

  /// Shows the tracks whose duration is unknown again.
  final VoidCallback onShowMissingDuration;

  /// Whether the page is narrow enough to keep the search behind an icon.
  final bool compact;

  /// Whether the search row stands open; only read while [compact].
  final bool searchOpen;

  const LibraryToolbar({
    super.key,
    required this.controller,
    this.focusNode,
    required this.query,
    required this.count,
    required this.hiddenMissingDuration,
    required this.kind,
    required this.sources,
    required this.sourceLabels,
    required this.sourceFilter,
    required this.sort,
    required this.filter,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onSourceFilter,
    required this.onSort,
    required this.onFilter,
    required this.onShowMissingDuration,
    required this.compact,
    required this.searchOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = compact ? _compactBar(context) : _wideBar(context);
    if (hiddenMissingDuration <= 0) return content;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        const SizedBox(height: CompactTokens.space4),
        _missingDurationNote(context),
      ],
    );
  }

  /// One row: source, filter and order. The search opens above it.
  Widget _compactBar(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (searchOpen) ...[
          SizedBox(
            height: CompactTokens.controlDefault,
            child: _searchField(autofocus: true),
          ),
          const SizedBox(height: CompactTokens.space8),
        ],
        SizedBox(
          height: CompactTokens.controlDefault,
          child: Row(
            children: [
              if (sources.length > 1) ...[
                LibrarySourceFilter(
                  sources: sources,
                  sourceLabels: sourceLabels,
                  sourceFilter: sourceFilter,
                  onSourceFilter: onSourceFilter,
                ),
                const SizedBox(width: CompactTokens.space8),
              ],
              _filterButton(context, label: false),
              // 排序和筛选是一路的：都改「看到哪些、按什么顺序」。
              const SizedBox(width: CompactTokens.space8),
              LibrarySortButton(sort: sort, onSort: onSort, compact: true),
            ],
          ),
        ),
      ],
    );
  }

  /// One row: search field, source and count, filter, order.
  Widget _wideBar(BuildContext context) {
    return SizedBox(
      height: CompactTokens.controlDefault,
      child: Row(
        children: [
          Expanded(child: _searchField()),
          // 结果数（和来源筛选）紧跟在搜索框后面：不留这道缝，
          // 「0 首」会贴在输入框的描边上。
          const SizedBox(width: CompactTokens.space12),
          ..._sourceAndCount(context),
          const SizedBox(width: CompactTokens.space12),
          _filterButton(context, label: true),
          const SizedBox(width: CompactTokens.space8),
          LibrarySortButton(sort: sort, onSort: onSort),
        ],
      ),
    );
  }

  Widget _searchField({bool autofocus = false}) {
    return LibrarySearchField(
      controller: controller,
      focusNode: focusNode,
      query: query,
      onChanged: onQueryChanged,
      onClear: onClearQuery,
      autofocus: autofocus,
    );
  }

  List<Widget> _sourceAndCount(BuildContext context) {
    final theme = Theme.of(context);
    return [
      if (sources.length > 1)
        LibrarySourceFilter(
          sources: sources,
          sourceLabels: sourceLabels,
          sourceFilter: sourceFilter,
          onSourceFilter: onSourceFilter,
        ),
      if (sources.length > 1) const SizedBox(width: CompactTokens.space8),
      Text(
        _countLabel(context),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ];
  }

  /// The count of what the list shows, in the unit of the scope.
  String _countLabel(BuildContext context) =>
      libraryCountLabel(context, count: count, kind: kind);

  Widget _filterButton(BuildContext context, {required bool label}) {
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      key: const ValueKey('library-filter'),
      onPressed: onFilter,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, CompactTokens.controlDefault),
        padding: const EdgeInsets.symmetric(horizontal: CompactTokens.space8),
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
      icon: Icon(
        filter.activeGroups == 0
            ? Icons.filter_alt_outlined
            : Icons.filter_alt_rounded,
        size: CompactTokens.icon16,
      ),
      // 窄窗口里这一行还要放排序，字会把它挤爆；
      // 只留图标，生效的组数在筛选面板里看得到。
      label: label
          ? Text(
              filter.activeGroups == 0
                  ? context.loc.libraryFilter
                  : '${context.loc.libraryFilter} ${filter.activeGroups}',
            )
          : const SizedBox.shrink(),
    );
  }

  /// States that dirty rows are out of the list, and offers to show them.
  ///
  /// A filter the reader cannot see is the thing this line exists to avoid:
  /// the count and the way back are both on the toolbar.
  Widget _missingDurationNote(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      key: const ValueKey('library-hidden-missing-duration'),
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: CompactTokens.icon14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: CompactTokens.space6),
        Expanded(
          child: Text(
            context.loc.libraryHiddenMissingDuration(hiddenMissingDuration),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          key: const ValueKey('library-show-missing-duration'),
          onPressed: onShowMissingDuration,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 28),
            padding: const EdgeInsets.symmetric(
              horizontal: CompactTokens.space8,
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: Text(context.loc.libraryShowHiddenDuration),
        ),
      ],
    );
  }
}
