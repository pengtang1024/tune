import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/core/l10n/genre_label.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/song_facts.dart';
import 'package:tune/features/library/domain/library_category.dart';
import 'package:tune/features/library/domain/library_facets.dart';
import 'package:tune/features/library/presentation/library_filter_labels.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';

typedef _Cover = ({String? path, String? url});

/// The catalog side of the library: the values of one category as cards.
class LibraryCategoryView extends StatelessWidget {
  final LibraryCategoryKind kind;
  final ValueChanged<LibraryCategoryKind> onKindChanged;
  final List<Song> songs;
  final LibraryFacets facets;
  final Map<String, SourceLabel> sourceLabels;
  final void Function(LibraryCategoryKind kind, Object value) onSelect;

  const LibraryCategoryView({
    super.key,
    required this.kind,
    required this.onKindChanged,
    required this.songs,
    required this.facets,
    required this.sourceLabels,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final entries = _entries(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            CompactTokens.pageGutter,
            0,
            CompactTokens.pageGutter,
            CompactTokens.space8,
          ),
          child: Row(
            children: [
              for (final category in LibraryCategoryKind.values) ...[
                ChoiceChip(
                  label: Text(_kindLabel(context, category)),
                  selected: category == kind,
                  onSelected: (_) => onKindChanged(category),
                ),
                const SizedBox(width: CompactTokens.space6),
              ],
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    context.loc.libraryNoMatchTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    CompactTokens.pageGutter,
                    0,
                    CompactTokens.pageGutter,
                    CompactTokens.space8,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        mainAxisExtent: 116,
                        crossAxisSpacing: CompactTokens.space8,
                        mainAxisSpacing: CompactTokens.space8,
                      ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _CategoryCard(
                      label: entry.label,
                      count: entry.count,
                      covers: entry.covers,
                      icon: _kindIcon(kind),
                      onTap: () => onSelect(kind, entry.value),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<({Object value, String label, int count, List<_Cover> covers})>
  _entries(BuildContext context) {
    final covers = _coversByValue();
    final entries = <({
      Object value,
      String label,
      int count,
      List<_Cover> covers,
    })>[];
    void add(Object value, String label, int count) {
      entries.add((
        value: value,
        label: label,
        count: count,
        covers: covers[value] ?? const [],
      ));
    }

    switch (kind) {
      case LibraryCategoryKind.genres:
        for (final entry in _top(facets.genres)) {
          add(entry.key, genreLabel(entry.key, context.loc), entry.value);
        }
      case LibraryCategoryKind.decades:
        for (final entry in _topInts(facets.decades)) {
          add(entry.key, filterDecadeLabel(entry.key), entry.value);
        }
      case LibraryCategoryKind.artists:
        for (final entry in _top(facets.artists)) {
          add(entry.key, entry.key, entry.value);
        }
      case LibraryCategoryKind.sources:
        for (final entry in _top(facets.sources)) {
          add(
            entry.key,
            sourceLabels[entry.key]?.name ?? entry.key,
            entry.value,
          );
        }
      case LibraryCategoryKind.languages:
        for (final entry in _top(facets.languages)) {
          add(entry.key, filterLanguageLabel(context, entry.key), entry.value);
        }
      case LibraryCategoryKind.formats:
        for (final entry in _top(facets.formats)) {
          add(entry.key, filterFormatLabel(entry.key), entry.value);
        }
    }
    return entries.take(30).toList(growable: false);
  }

  Map<Object, List<_Cover>> _coversByValue() {
    final covers = <Object, List<_Cover>>{};
    for (final song in songs) {
      for (final value in _valuesOfSong(song)) {
        final list = covers.putIfAbsent(value, () => []);
        if (list.length >= 4) continue;
        final cover = (path: song.albumArtPath, url: song.artworkUrl);
        if (cover.path == null && cover.url == null) continue;
        list.add(cover);
      }
    }
    return covers;
  }

  List<Object> _valuesOfSong(Song song) => switch (kind) {
    LibraryCategoryKind.genres => [
      for (final genre in (song.genres?.isNotEmpty ?? false)
          ? song.genres!
          : [if (song.genre != null) song.genre!])
        genre.trim().toLowerCase(),
    ],
    LibraryCategoryKind.decades => [
      if ((song.year ?? 0) > 0) ((song.year ?? 0) ~/ 10) * 10,
    ],
    LibraryCategoryKind.artists => [
      if (song.artist.trim().isNotEmpty) song.artist,
    ],
    LibraryCategoryKind.sources => [song.sourceId ?? 'local'],
    LibraryCategoryKind.languages => [
      if (languageKeyOf(song) != null) languageKeyOf(song)!,
    ],
    LibraryCategoryKind.formats => [formatOfSong(song)],
  };

  static List<MapEntry<String, int>> _top(Map<String, int> values) =>
      (values.entries.toList()
            ..sort((left, right) => right.value.compareTo(left.value)))
          .take(30)
          .toList(growable: false);

  static List<MapEntry<int, int>> _topInts(Map<int, int> values) =>
      (values.entries.toList()
            ..sort((left, right) => left.key.compareTo(right.key)))
          .take(30)
          .toList(growable: false);

  static String _kindLabel(BuildContext context, LibraryCategoryKind kind) =>
      switch (kind) {
        LibraryCategoryKind.genres => context.loc.libraryFilterGenres,
        LibraryCategoryKind.decades => context.loc.libraryFilterDecades,
        LibraryCategoryKind.artists => context.loc.libraryFilterArtists,
        LibraryCategoryKind.sources => context.loc.libraryFilterSources,
        LibraryCategoryKind.languages => context.loc.libraryFilterLanguages,
        LibraryCategoryKind.formats => context.loc.libraryFilterFormats,
      };

  static IconData _kindIcon(LibraryCategoryKind kind) => switch (kind) {
    LibraryCategoryKind.genres => Icons.category_rounded,
    LibraryCategoryKind.decades => Icons.calendar_month_rounded,
    LibraryCategoryKind.artists => Icons.person_rounded,
    LibraryCategoryKind.sources => Icons.podcasts_rounded,
    LibraryCategoryKind.languages => Icons.translate_rounded,
    LibraryCategoryKind.formats => Icons.audio_file_rounded,
  };
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final int count;
  final List<_Cover> covers;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.count,
    required this.covers,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: CompactTokens.borderRadius8,
      child: InkWell(
        onTap: onTap,
        borderRadius: CompactTokens.borderRadius8,
        child: Padding(
          padding: const EdgeInsets.all(CompactTokens.space8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: covers.isEmpty
                    ? _iconBlock(theme)
                    : _mosaic(theme),
              ),
              const SizedBox(height: CompactTokens.space6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
              Text(
                '$count',
                style: CompactTypography.mono(
                  theme.colorScheme.onSurfaceVariant,
                  size: CompactTypeScale.mark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBlock(ThemeData theme) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: CompactTokens.borderRadius6,
    ),
    child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
  );

  Widget _mosaic(ThemeData theme) {
    final items = [...covers];
    while (items.length < 4) {
      items.add((path: null, url: null));
    }
    return GridView.count(
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: [
        for (final cover in items.take(4))
          cover.path == null && cover.url == null
              ? Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    icon,
                    size: CompactTokens.icon14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : ArtworkThumb(
                  path: cover.path,
                  imageUrl: cover.url,
                  size: 40,
                  radius: CompactTokens.radius6,
                ),
      ],
    );
  }
}
