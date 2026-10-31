import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/core/l10n/genre_label.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_category.dart';
import 'package:tune/features/library/domain/library_facets.dart';
import 'package:tune/features/library/domain/library_filter.dart';
import 'package:tune/features/library/presentation/library_filter_labels.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The category tree beside the library.
///
/// Collapsed it is an icon rail; expanded it names the six ways into the
/// catalog and the first values of each. A click on a kind opens the
/// category view; a click on a value narrows the song list to it.
class LibraryCategoryTree extends ConsumerWidget {
  final bool expanded;
  final LibraryCategoryKind selectedKind;
  final LibraryFilter filter;
  final Map<String, SourceLabel> sourceLabels;
  final VoidCallback onAllSongs;
  final ValueChanged<LibraryCategoryKind> onKind;
  final void Function(LibraryCategoryKind kind, Object value) onValue;
  final VoidCallback onToggle;

  const LibraryCategoryTree({
    super.key,
    required this.expanded,
    required this.selectedKind,
    required this.filter,
    required this.sourceLabels,
    required this.onAllSongs,
    required this.onKind,
    required this.onValue,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facets =
        ref.watch(libraryFacetsProvider).valueOrNull ?? LibraryFacets.empty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: expanded ? 168 : 48,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: expanded
          ? _expanded(context, facets)
          : _collapsed(context),
    );
  }

  Widget _collapsed(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: CompactTokens.space8),
      child: Column(
        children: [
          _iconButton(
            context,
            icon: Icons.library_music_rounded,
            message: context.loc.libraryAllSongs,
            onPressed: onAllSongs,
          ),
          const SizedBox(height: CompactTokens.space4),
          for (final kind in LibraryCategoryKind.values)
            _iconButton(
              context,
              icon: _iconOf(kind),
              message: _labelOf(context, kind),
              selected: selectedKind == kind,
              onPressed: () => onKind(kind),
            ),
          const SizedBox(height: CompactTokens.space4),
          _iconButton(
            context,
            icon: Icons.chevron_right_rounded,
            message: context.loc.libraryTreeExpand,
            onPressed: onToggle,
          ),
        ],
      ),
    );
  }

  Widget _expanded(BuildContext context, LibraryFacets facets) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CompactTokens.space8,
            CompactTokens.space8,
            CompactTokens.space4,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onAllSongs,
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: CompactTokens.space4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.library_music_rounded, size: 16),
                  label: Text(
                    context.loc.libraryAllSongs,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
              ),
              TuneTooltip(
                message: context.loc.libraryTreeCollapse,
                child: IconButton(
                  onPressed: onToggle,
                  icon: const Icon(Icons.chevron_left_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              CompactTokens.space4,
              CompactTokens.space4,
              CompactTokens.space4,
              CompactTokens.space8,
            ),
            children: [
              for (final kind in LibraryCategoryKind.values) ...[
                _kindRow(context, kind, theme),
                for (final entry in _valuesOf(context, kind, facets))
                  _valueRow(context, kind, entry.key, entry.label, entry.count),
                const SizedBox(height: CompactTokens.space4),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _kindRow(BuildContext context, LibraryCategoryKind kind, ThemeData theme) {
    final selected = selectedKind == kind;
    return TextButton(
      onPressed: () => onKind(kind),
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(
          horizontal: CompactTokens.space4,
          vertical: CompactTokens.space4,
        ),
        visualDensity: VisualDensity.compact,
        foregroundColor: selected ? theme.colorScheme.primary : null,
      ),
      child: Row(
        children: [
          Icon(_iconOf(kind), size: 14),
          const SizedBox(width: CompactTokens.space6),
          Text(_labelOf(context, kind), style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }

  Widget _valueRow(
    BuildContext context,
    LibraryCategoryKind kind,
    Object value,
    String label,
    int count,
  ) {
    final active = _isActive(kind, value);
    return Padding(
      padding: const EdgeInsets.only(left: CompactTokens.space16),
      child: TextButton(
        onPressed: () => onValue(kind, value),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(
            horizontal: CompactTokens.space4,
            vertical: 2,
          ),
          visualDensity: VisualDensity.compact,
          foregroundColor: active
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isActive(LibraryCategoryKind kind, Object value) => switch (kind) {
    LibraryCategoryKind.genres => filter.genres.contains(value),
    LibraryCategoryKind.decades => filter.decades.contains(value),
    LibraryCategoryKind.artists => filter.artists.contains(value),
    LibraryCategoryKind.sources => filter.sources.contains(value),
    LibraryCategoryKind.languages => filter.languages.contains(value),
    LibraryCategoryKind.formats => filter.formats.contains(value),
  };

  Widget _iconButton(
    BuildContext context, {
    required IconData icon,
    required String message,
    required VoidCallback onPressed,
    bool selected = false,
  }) {
    final theme = Theme.of(context);
    return TuneTooltip(
      message: message,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: CompactTokens.icon18),
        style: IconButton.styleFrom(
          foregroundColor: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          backgroundColor: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : null,
          fixedSize: const Size.square(CompactTokens.controlSmall),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  static IconData _iconOf(LibraryCategoryKind kind) => switch (kind) {
    LibraryCategoryKind.genres => Icons.category_rounded,
    LibraryCategoryKind.decades => Icons.calendar_month_rounded,
    LibraryCategoryKind.artists => Icons.person_rounded,
    LibraryCategoryKind.sources => Icons.podcasts_rounded,
    LibraryCategoryKind.languages => Icons.translate_rounded,
    LibraryCategoryKind.formats => Icons.audio_file_rounded,
  };

  static String _labelOf(BuildContext context, LibraryCategoryKind kind) =>
      switch (kind) {
        LibraryCategoryKind.genres => context.loc.libraryFilterGenres,
        LibraryCategoryKind.decades => context.loc.libraryFilterDecades,
        LibraryCategoryKind.artists => context.loc.libraryFilterArtists,
        LibraryCategoryKind.sources => context.loc.libraryFilterSources,
        LibraryCategoryKind.languages => context.loc.libraryFilterLanguages,
        LibraryCategoryKind.formats => context.loc.libraryFilterFormats,
      };

  List<({Object key, String label, int count})> _valuesOf(
    BuildContext context,
    LibraryCategoryKind kind,
    LibraryFacets facets,
  ) {
    final values = <({Object key, String label, int count})>[];
    switch (kind) {
      case LibraryCategoryKind.genres:
        for (final entry in _top(facets.genres)) {
          values.add((
            key: entry.key,
            label: genreLabel(entry.key, context.loc),
            count: entry.value,
          ));
        }
      case LibraryCategoryKind.decades:
        for (final entry in _topInts(facets.decades)) {
          values.add((
            key: entry.key,
            label: filterDecadeLabel(entry.key),
            count: entry.value,
          ));
        }
      case LibraryCategoryKind.artists:
        for (final entry in _top(facets.artists)) {
          values.add((key: entry.key, label: entry.key, count: entry.value));
        }
      case LibraryCategoryKind.sources:
        for (final entry in _top(facets.sources)) {
          values.add((
            key: entry.key,
            label: sourceLabels[entry.key]?.name ?? entry.key,
            count: entry.value,
          ));
        }
      case LibraryCategoryKind.languages:
        for (final entry in _top(facets.languages)) {
          values.add((
            key: entry.key,
            label: filterLanguageLabel(context, entry.key),
            count: entry.value,
          ));
        }
      case LibraryCategoryKind.formats:
        for (final entry in _top(facets.formats)) {
          values.add((
            key: entry.key,
            label: filterFormatLabel(entry.key),
            count: entry.value,
          ));
        }
    }
    return values.take(6).toList(growable: false);
  }

  static List<MapEntry<String, int>> _top(Map<String, int> values) =>
      (values.entries.toList()
            ..sort((left, right) => right.value.compareTo(left.value)))
          .take(6)
          .toList(growable: false);

  static List<MapEntry<int, int>> _topInts(Map<int, int> values) =>
      (values.entries.toList()
            ..sort((left, right) => left.key.compareTo(right.key)))
          .take(6)
          .toList(growable: false);
}
