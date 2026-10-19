import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';

/// Value of the source filter that stands for "every source".
const String allSourcesFilterValue = '__all_sources__';

/// Search field, source filter, result count and scan action of the library.
class LibraryToolbar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final int filteredCount;
  final List<String> sources;
  final Map<String, String> sourceNames;
  final String? sourceFilter;
  final bool scanning;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<String?> onSourceFilter;
  final VoidCallback? onScan;

  const LibraryToolbar({
    super.key,
    required this.controller,
    required this.query,
    required this.filteredCount,
    required this.sources,
    required this.sourceNames,
    required this.sourceFilter,
    required this.scanning,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onSourceFilter,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: CompactTokens.inputHeight,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onQueryChanged,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainer,
                hintText: context.loc.search,
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
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
                    : IconButton(
                        tooltip: '清除搜索',
                        onPressed: onClearQuery,
                        icon: const Icon(Icons.close_rounded, size: 14),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
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
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
            ),
          ),
          if (sources.length > 1) ...[
            const SizedBox(width: CompactTokens.space8),
            _SourceFilter(
              sources: sources,
              sourceNames: sourceNames,
              sourceFilter: sourceFilter,
              onSourceFilter: onSourceFilter,
            ),
          ],
          const SizedBox(width: CompactTokens.space8),
          Text(
            '$filteredCount 首',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: CompactTokens.space4),
          _ScanButton(scanning: scanning, onPressed: onScan),
        ],
      ),
    );
  }
}

/// Chip that opens the source filter menu.
class _SourceFilter extends StatelessWidget {
  final List<String> sources;
  final Map<String, String> sourceNames;
  final String? sourceFilter;
  final ValueChanged<String?> onSourceFilter;

  const _SourceFilter({
    required this.sources,
    required this.sourceNames,
    required this.sourceFilter,
    required this.onSourceFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = sourceFilter != null;
    final label = sourceFilter == null
        ? '全部来源'
        : (sourceNames[sourceFilter] ?? sourceFilter!);

    return PopupMenuButton<String>(
      tooltip: '筛选来源',
      padding: EdgeInsets.zero,
      initialValue: sourceFilter ?? allSourcesFilterValue,
      onSelected: (value) {
        onSourceFilter(value == allSourcesFilterValue ? null : value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: allSourcesFilterValue,
          height: 36,
          child: Text('全部来源'),
        ),
        for (final sourceId in sources)
          PopupMenuItem<String>(
            value: sourceId,
            height: 36,
            child: Text(sourceNames[sourceId] ?? sourceId),
          ),
      ],
      child: Container(
        height: CompactTokens.inputHeight,
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
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
          ],
        ),
      ),
    );
  }
}

/// Action that rescans every enabled source.
class _ScanButton extends StatelessWidget {
  final bool scanning;
  final VoidCallback? onPressed;

  const _ScanButton({required this.scanning, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      tooltip: '扫描全部音源',
      onPressed: onPressed,
      icon: scanning
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh_rounded, size: 18),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(CompactTokens.controlSmall),
        minimumSize: const Size.square(CompactTokens.controlSmall),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        foregroundColor: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
