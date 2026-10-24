import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/shared/ui/compact_spinner.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// Value of the source filter that stands for "every source".
const String allSourcesFilterValue = '__all_sources__';

/// Search field, source filter, result count and scan action of the library.
///
/// The scan action watches the scan on its own: a running scan reports its
/// progress every percent, and the list of the library must not be rebuilt
/// by it.
class LibraryToolbar extends ConsumerWidget {
  final TextEditingController controller;
  final String query;
  final int filteredCount;
  final List<String> sources;
  final Map<String, SourceLabel> sourceLabels;
  final String? sourceFilter;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<String?> onSourceFilter;
  final VoidCallback onScan;

  const LibraryToolbar({
    super.key,
    required this.controller,
    required this.query,
    required this.filteredCount,
    required this.sources,
    required this.sourceLabels,
    required this.sourceFilter,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onSourceFilter,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scanning = ref.watch(
      libraryControllerProvider.select(
        (value) {
          final state = value.valueOrNull;
          if (state == null) return false;
          return state.isScanning || state.isLoading;
        },
      ),
    );

    return SizedBox(
      height: CompactTokens.inputHeight,
      child: Row(
        children: [
          Expanded(
            // The field keeps a readable width instead of stretching into a
            // thin ribbon, and the actions of the row keep the far end of
            // the page.
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
          // The page heading already counts the whole library. The field of
          // the toolbar only speaks up when a search or a source narrows the
          // list, so the same number is not written twice on the page.
          if (query.trim().isNotEmpty || sourceFilter != null) ...[
            Text(
              context.loc.libraryTrackCount(filteredCount),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: CompactTokens.space8),
          ],
          _ScanButton(
            scanning: scanning,
            onPressed: scanning ? null : onScan,
          ),
        ],
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
      // The button says what it filters in its tooltip: the words of a chip
      // belong to the mouse, not to the toolbar.
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

/// Action that rescans every enabled source.
class _ScanButton extends StatelessWidget {
  final bool scanning;
  final VoidCallback? onPressed;

  const _ScanButton({required this.scanning, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TuneTooltip(
      message: context.loc.libraryScanAllSources,
      child: IconButton(
        onPressed: onPressed,
        icon: scanning
            ? const CompactSpinner.small()
            : const Icon(Icons.refresh_rounded, size: CompactTokens.icon18),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(CompactTokens.controlSmall),
          minimumSize: const Size.square(CompactTokens.controlSmall),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          foregroundColor: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
