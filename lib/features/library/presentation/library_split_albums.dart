import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/library/domain/library_album.dart';
import 'package:tune/features/library/domain/library_layout.dart';

/// 分栏视图的左半：这一类的分组列表。
///
/// 它不替换右边的曲目表，而是与它同时在场——读者一眼能看出「这条曲目属哪
/// 一组」，也能看到「这一组里有什么」。名字由内容分类决定（专辑 / 节目 /
/// 书），这里只负责画。
class LibrarySplitAlbums extends StatelessWidget {
  const LibrarySplitAlbums({
    super.key,
    required this.albums,
    required this.selectedKey,
    required this.onPick,
    this.groupingLabel,
    this.totalTracks = 0,
  });

  final List<LibraryAlbum> albums;
  final String? selectedKey;
  final ValueChanged<String?> onPick;
  final LibraryGroupingLabel? groupingLabel;
  final int totalTracks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final title = switch (groupingLabel) {
      LibraryGroupingLabel.show => loc.libraryViewShows,
      LibraryGroupingLabel.book => loc.libraryViewBooks,
      _ => loc.libraryViewAlbums,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CompactTokens.space12,
            CompactTokens.space8,
            CompactTokens.space12,
            CompactTokens.space4,
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: const ValueKey('library-split-groups'),
            padding: const EdgeInsets.only(bottom: CompactTokens.space8),
            itemCount: albums.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _Row(
                  label: loc.libraryAllSongs,
                  count: totalTracks,
                  selected: selectedKey == null,
                  onTap: () => onPick(null),
                  rowKey: const ValueKey('library-split-all'),
                );
              }
              final album = albums[index - 1];
              return _Row(
                label: album.name.isEmpty ? loc.libraryUnknownAlbum : album.name,
                count: album.trackCount,
                selected: album.key == selectedKey,
                onTap: () => onPick(album.key),
                rowKey: ValueKey('library-split-${album.key}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.rowKey,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Key rowKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: rowKey,
      onTap: onTap,
      child: Container(
        height: CompactTokens.libraryRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: CompactTokens.space12),
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: CompactTokens.space8),
            Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
