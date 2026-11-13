import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// Value of the source filter that stands for "every source".
const String allSourcesFilterValue = '__all_sources__';

/// Chip that opens the source filter menu.
class LibrarySourceFilter extends StatelessWidget {
  final List<String> sources;
  final Map<String, SourceLabel> sourceLabels;
  final String? sourceFilter;
  final ValueChanged<String?> onSourceFilter;

  const LibrarySourceFilter({
    super.key,
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
        key: const ValueKey('library-source-filter'),
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
