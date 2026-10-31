import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/core/l10n/genre_label.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/library/domain/library_filter.dart';
import 'package:tune/features/library/presentation/library_filter_labels.dart';

/// The filters that are in force, as removable chips under the toolbar.
class LibraryFilterChips extends StatelessWidget {
  final LibraryFilter filter;
  final Map<String, SourceLabel> sourceLabels;
  final ValueChanged<LibraryFilter> onChanged;

  const LibraryFilterChips({
    super.key,
    required this.filter,
    required this.sourceLabels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (filter.isEmpty) return const SizedBox.shrink();
    final chips = <Widget>[
      if (filter.status != LibraryStatusFilter.all)
        _chip(
          context,
          filterStatusLabel(context, filter.status),
          () => onChanged(filter.copyWith(status: LibraryStatusFilter.all)),
        ),
      for (final genre in filter.genres)
        _chip(
          context,
          genreLabel(genre, context.loc),
          () => onChanged(
            filter.copyWith(
              genres: {...filter.genres}..remove(genre),
            ),
          ),
        ),
      for (final decade in filter.decades)
        _chip(
          context,
          filterDecadeLabel(decade),
          () => onChanged(
            filter.copyWith(
              decades: {...filter.decades}..remove(decade),
            ),
          ),
        ),
      for (final artist in filter.artists)
        _chip(
          context,
          artist,
          () => onChanged(
            filter.copyWith(
              artists: {...filter.artists}..remove(artist),
            ),
          ),
        ),
      for (final source in filter.sources)
        _chip(
          context,
          sourceLabels[source]?.name ?? source,
          () => onChanged(
            filter.copyWith(
              sources: {...filter.sources}..remove(source),
            ),
          ),
        ),
      for (final language in filter.languages)
        _chip(
          context,
          filterLanguageLabel(language),
          () => onChanged(
            filter.copyWith(
              languages: {...filter.languages}..remove(language),
            ),
          ),
        ),
      for (final format in filter.formats)
        _chip(
          context,
          filterFormatLabel(format),
          () => onChanged(
            filter.copyWith(
              formats: {...filter.formats}..remove(format),
            ),
          ),
        ),
      for (final bucket in filter.durations)
        _chip(
          context,
          filterDurationLabel(context, bucket),
          () => onChanged(
            filter.copyWith(
              durations: {...filter.durations}..remove(bucket),
            ),
          ),
        ),
      for (final window in filter.added)
        _chip(
          context,
          filterAddedLabel(context, window),
          () => onChanged(
            filter.copyWith(
              added: {...filter.added}..remove(window),
            ),
          ),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CompactTokens.pageGutter,
        0,
        CompactTokens.pageGutter,
        CompactTokens.space6,
      ),
      child: Wrap(
        spacing: CompactTokens.space6,
        runSpacing: CompactTokens.space4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...chips,
          TextButton(
            key: const ValueKey('library-filter-clear-chips'),
            onPressed: () => onChanged(LibraryFilter.empty),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(context.loc.libraryFilterClearAll),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, VoidCallback onDeleted) {
    return InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close_rounded, size: CompactTokens.icon14),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
