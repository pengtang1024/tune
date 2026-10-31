import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/core/l10n/genre_label.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_facets.dart';
import 'package:tune/features/library/domain/library_filter.dart';
import 'package:tune/features/library/presentation/library_filter_labels.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// Opens the filter panel at the right edge of the window.
Future<void> showLibraryFilterPanel(
  BuildContext context, {
  required Map<String, SourceLabel> sourceLabels,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      alignment: Alignment.centerRight,
      insetPadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 340,
        height: MediaQuery.sizeOf(context).height,
        child: LibraryFilterPanel(sourceLabels: sourceLabels),
      ),
    ),
  );
}

/// The groups of the library filter.
///
/// Every click changes the filter at once; the page reads the new window
/// while the panel stays open, so the reader sees the result under it.
class LibraryFilterPanel extends ConsumerWidget {
  final Map<String, SourceLabel> sourceLabels;

  const LibraryFilterPanel({super.key, required this.sourceLabels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(
      libraryControllerProvider.select(
        (value) => value.valueOrNull?.filter ?? LibraryFilter.empty,
      ),
    );
    final facets =
        ref.watch(libraryFacetsProvider).valueOrNull ?? LibraryFacets.empty;
    final theme = Theme.of(context);

    void setFilter(LibraryFilter next) {
      unawaited(
        ref.read(libraryControllerProvider.notifier).setFilter(next),
      );
    }

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CompactTokens.space16,
                CompactTokens.space12,
                CompactTokens.space8,
                CompactTokens.space8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.loc.libraryFilter,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  TuneTooltip(
                    message: context.loc.cancel,
                    child: IconButton(
                      key: const ValueKey('library-filter-close'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                key: const ValueKey('library-filter-panel'),
                padding: const EdgeInsets.fromLTRB(
                  CompactTokens.space16,
                  CompactTokens.space12,
                  CompactTokens.space16,
                  CompactTokens.space12,
                ),
                children: [
                  _section(
                    context,
                    context.loc.libraryFilterStatus,
                    [
                      for (final status in LibraryStatusFilter.values)
                        ChoiceChip(
                          label: Text(
                            filterStatusLabel(context, status),
                          ),
                          selected: filter.status == status,
                          onSelected: (_) => setFilter(
                            filter.copyWith(status: status),
                          ),
                        ),
                    ],
                  ),
                  if (facets.genres.isNotEmpty)
                    _section(
                      context,
                      context.loc.libraryFilterGenres,
                      [
                        for (final entry in _top(facets.genres))
                          FilterChip(
                            label: Text(
                              '${genreLabel(entry.key, context.loc)} · '
                              '${entry.value}',
                            ),
                            selected: filter.genres.contains(entry.key),
                            onSelected: (_) => setFilter(
                              filter.copyWith(
                                genres: _toggled(filter.genres, entry.key),
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (facets.decades.isNotEmpty)
                    _section(
                      context,
                      context.loc.libraryFilterDecades,
                      [
                        for (final entry in _sortedInts(facets.decades))
                          FilterChip(
                            label: Text(
                              '${filterDecadeLabel(entry.key)} · '
                              '${entry.value}',
                            ),
                            selected: filter.decades.contains(entry.key),
                            onSelected: (_) => setFilter(
                              filter.copyWith(
                                decades: _toggled(filter.decades, entry.key),
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (facets.artists.isNotEmpty)
                    _section(
                      context,
                      context.loc.libraryFilterArtists,
                      [
                        for (final entry in _top(facets.artists))
                          FilterChip(
                            label: Text('${entry.key} · ${entry.value}'),
                            selected: filter.artists.contains(entry.key),
                            onSelected: (_) => setFilter(
                              filter.copyWith(
                                artists: _toggled(filter.artists, entry.key),
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (facets.sources.isNotEmpty)
                    _section(
                      context,
                      context.loc.libraryFilterSources,
                      [
                        for (final entry in _top(facets.sources))
                          FilterChip(
                            label: Text(
                              '${sourceLabels[entry.key]?.name ?? entry.key}'
                              ' · ${entry.value}',
                            ),
                            selected: filter.sources.contains(entry.key),
                            onSelected: (_) => setFilter(
                              filter.copyWith(
                                sources: _toggled(filter.sources, entry.key),
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (facets.languages.isNotEmpty)
                    _section(
                      context,
                      context.loc.libraryFilterLanguages,
                      [
                        for (final entry in _top(facets.languages))
                          FilterChip(
                            label: Text(
                              '${filterLanguageLabel(entry.key)} · '
                              '${entry.value}',
                            ),
                            selected: filter.languages.contains(entry.key),
                            onSelected: (_) => setFilter(
                              filter.copyWith(
                                languages: _toggled(
                                  filter.languages,
                                  entry.key,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (facets.formats.isNotEmpty)
                    _section(
                      context,
                      context.loc.libraryFilterFormats,
                      [
                        for (final entry in _top(facets.formats))
                          FilterChip(
                            label: Text(
                              '${filterFormatLabel(entry.key)} · '
                              '${entry.value}',
                            ),
                            selected: filter.formats.contains(entry.key),
                            onSelected: (_) => setFilter(
                              filter.copyWith(
                                formats: _toggled(filter.formats, entry.key),
                              ),
                            ),
                          ),
                      ],
                    ),
                  _section(
                    context,
                    context.loc.libraryFilterDurations,
                    [
                      for (final bucket in LibraryDurationBucket.values)
                        FilterChip(
                          label: Text(
                            '${filterDurationLabel(context, bucket)} · '
                            '${facets.durations[bucket] ?? 0}',
                          ),
                          selected: filter.durations.contains(bucket),
                          onSelected: (_) => setFilter(
                            filter.copyWith(
                              durations: _toggled(filter.durations, bucket),
                            ),
                          ),
                        ),
                    ],
                  ),
                  _section(
                    context,
                    context.loc.libraryFilterAdded,
                    [
                      for (final window in LibraryAddedWindow.values)
                        FilterChip(
                          label: Text(
                            '${filterAddedLabel(context, window)} · '
                            '${facets.added[window] ?? 0}',
                          ),
                          selected: filter.added.contains(window),
                          onSelected: (_) => setFilter(
                            filter.copyWith(
                              added: _toggled(filter.added, window),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(CompactTokens.space12),
              child: TextButton(
                key: const ValueKey('library-filter-clear'),
                onPressed: filter.isEmpty
                    ? null
                    : () => setFilter(LibraryFilter.empty),
                child: Text(context.loc.libraryFilterClearAll),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _section(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: CompactTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: CompactTokens.space6),
          Wrap(
            spacing: CompactTokens.space6,
            runSpacing: CompactTokens.space6,
            children: children,
          ),
        ],
      ),
    );
  }

  static List<MapEntry<String, int>> _top(Map<String, int> values) {
    final entries = values.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    return entries.take(40).toList(growable: false);
  }

  static List<MapEntry<int, int>> _sortedInts(Map<int, int> values) {
    final entries = values.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return entries;
  }

  static Set<T> _toggled<T>(Set<T> values, T value) {
    final next = {...values};
    if (!next.remove(value)) next.add(value);
    return next;
  }
}
