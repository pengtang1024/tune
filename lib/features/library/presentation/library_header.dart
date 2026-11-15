import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The heading of the library.
///
/// One title, the account of what the library holds, and the two whole-page
/// actions behind a menu. The view switch and the search belong to the
/// toolbar: they change how the list is read, not what the page is.
class LibraryHeader extends StatelessWidget {
  /// What the library holds: tracks, albums and sources.
  final String summary;

  /// Puts the whole visible list into the queue.
  final VoidCallback? onAddAll;

  /// Scans every configured source again.
  final VoidCallback onScan;

  /// Whether a scan is already running; the menu item waits then.
  final bool scanning;

  /// Opens the online search sheet, when the page was given an opener.
  ///
  /// The entry is left out when it is null: a button that does nothing is
  /// worse than one that is not there.
  final VoidCallback? onSearchOnline;

  /// The content the page is scoped to, when it names exactly one kind.
  ///
  /// Null while the filter holds several kinds or none at all; the menu then
  /// says it shows the kinds, not one of them.
  final ContentKind? selectedKind;

  /// Narrows the page to one kind: songs, shows, books or stations.
  final ValueChanged<ContentKind> onKind;

  /// Whether the library holds anything besides songs.
  ///
  /// A library of songs has no use for a menu that offers shows; the entry
  /// is left out instead of opening an empty list.
  final bool showKindMenu;

  /// Opens the wall of albums.
  final VoidCallback? onAlbums;

  /// Whether the page is already showing the albums.
  final bool albumsActive;

  /// Whether the category tree stands open.
  final bool treeExpanded;
  final VoidCallback onToggleTree;

  const LibraryHeader({
    super.key,
    required this.summary,
    required this.onAddAll,
    required this.onScan,
    required this.scanning,
    required this.onSearchOnline,
    required this.selectedKind,
    required this.onKind,
    required this.showKindMenu,
    required this.onAlbums,
    required this.albumsActive,
    required this.treeExpanded,
    required this.onToggleTree,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = CompactTypography.asDisplay(
      theme.textTheme.displayMedium,
      size: CompactTypeScale.displayMedium,
      height: 0.95,
    );

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          TuneTooltip(
            message: treeExpanded
                ? context.loc.libraryTreeCollapse
                : context.loc.libraryTreeExpand,
            child: IconButton(
              key: const ValueKey('library-tree-toggle'),
              onPressed: onToggleTree,
              icon: Icon(
                treeExpanded
                    ? Icons.menu_open_rounded
                    : Icons.menu_rounded,
                size: CompactTokens.icon18,
              ),
              style: IconButton.styleFrom(
                fixedSize: const Size.square(CompactTokens.controlDefault),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(width: CompactTokens.space4),
          Text(context.loc.libraryTitle, style: titleStyle),
          const SizedBox(width: CompactTokens.space12),
          Expanded(
            child: Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CompactTypography.mono(
                theme.colorScheme.onSurfaceVariant,
                size: CompactTypeScale.mark,
              ),
            ),
          ),
          if (showKindMenu) ...[
            const SizedBox(width: CompactTokens.space12),
            TuneTooltip(
              message: context.loc.libraryFilterKinds,
              child: PopupMenuButton<ContentKind>(
                key: const ValueKey('library-content-kind'),
                initialValue: selectedKind,
                onSelected: onKind,
                itemBuilder: (context) => [
                  for (final kind in ContentKind.values)
                    CheckedPopupMenuItem(
                      value: kind,
                      checked: kind == selectedKind,
                      child: Text(_kindLabel(context, kind)),
                    ),
                ],
                child: IgnorePointer(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    style: _scopeStyle(
                      theme,
                      selectedKind != null &&
                          selectedKind != ContentKind.music,
                    ),
                    icon: Icon(
                      selectedKind == null
                          ? Icons.tune_rounded
                          : _kindIcon(selectedKind!),
                      size: CompactTokens.icon16,
                    ),
                    label: Text(
                      selectedKind == null
                          ? context.loc.libraryFilterKinds
                          : _kindLabel(context, selectedKind!),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: CompactTokens.space8),
          ],
          if (onAlbums != null) ...[
            const SizedBox(width: CompactTokens.space12),
            OutlinedButton.icon(
              key: const ValueKey('library-albums'),
              onPressed: onAlbums,
              style: _scopeStyle(theme, albumsActive),
              icon: const Icon(
                Icons.grid_view_rounded,
                size: CompactTokens.icon16,
              ),
              label: Text(context.loc.libraryViewAlbums),
            ),
            const SizedBox(width: CompactTokens.space8),
          ],
          if (onSearchOnline != null) ...[
            const SizedBox(width: CompactTokens.space12),
            OutlinedButton.icon(
              onPressed: onSearchOnline,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, CompactTokens.controlDefault),
                padding: const EdgeInsets.symmetric(
                  horizontal: CompactTokens.space12,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              icon: const Icon(
                Icons.travel_explore_rounded,
                size: CompactTokens.icon16,
              ),
              label: Text(context.loc.searchOnlineTitle),
            ),
            const SizedBox(width: CompactTokens.space8),
          ],
          TuneTooltip(
            message: context.loc.libraryMoreActions,
            child: PopupMenuButton<String>(
              key: const ValueKey('library-more'),
              icon: const Icon(Icons.more_horiz),
              onSelected: (action) {
              switch (action) {
                case 'scan':
                  onScan();
                case 'addAll':
                  onAddAll?.call();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'scan',
                enabled: !scanning,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    scanning
                        ? Icons.hourglass_top_rounded
                        : Icons.refresh_rounded,
                    size: CompactTokens.icon16,
                  ),
                  title: Text(context.loc.libraryScanAllSources),
                ),
              ),
              PopupMenuItem(
                value: 'addAll',
                enabled: onAddAll != null,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.playlist_add_rounded,
                    size: CompactTokens.icon16,
                  ),
                  title: Text(context.loc.libraryAddAllToQueue),
                ),
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }

  /// The look both page-wide entries share: outlined, and tinted while it is
  /// the one the page is showing.
  ButtonStyle _scopeStyle(ThemeData theme, bool active) =>
      OutlinedButton.styleFrom(
        minimumSize: const Size(0, CompactTokens.controlDefault),
        padding: const EdgeInsets.symmetric(
          horizontal: CompactTokens.space12,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        foregroundColor: active ? theme.colorScheme.primary : null,
        backgroundColor: active
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : null,
        side: BorderSide(
          color: active
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
      );
}

String _kindLabel(BuildContext context, ContentKind kind) => switch (kind) {
  ContentKind.music => context.loc.contentKindMusic,
  ContentKind.podcast => context.loc.contentKindPodcast,
  ContentKind.audiobook => context.loc.contentKindAudiobook,
  ContentKind.radio => context.loc.contentKindRadio,
  ContentKind.soundEffect => context.loc.contentKindSoundEffect,
};

IconData _kindIcon(ContentKind kind) => switch (kind) {
  ContentKind.music => Icons.music_note_rounded,
  ContentKind.podcast => Icons.podcasts_rounded,
  ContentKind.audiobook => Icons.record_voice_over_rounded,
  ContentKind.radio => Icons.radio_rounded,
  ContentKind.soundEffect => Icons.graphic_eq_rounded,
};
