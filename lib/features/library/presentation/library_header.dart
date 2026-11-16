import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/features/library/presentation/library_count_label.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The heading of the library.
///
/// A wide window shows the title, the account of what the library holds and the
/// two whole-page entries (albums, online search) beside it; the view switch and
/// the search belong to the toolbar, because they change how the list is read.
///
/// A narrow window ([compact]) says only what the page is and what the list
/// holds right now: the count of the matching rows, one icon that opens the
/// search, and the page entries moved into the menu. Three rows of chrome with
/// two outlined buttons over a squeezed account of the library is a desktop
/// page wearing a phone shell — and the list, which is the point of the page,
/// ends up the smallest thing on screen.
class LibraryHeader extends StatelessWidget {
  /// What the library holds: tracks, albums and sources.
  final String summary;

  /// How many rows the list shows right now, in the unit of [kind].
  final int count;

  /// The content the page is scoped to, when it names exactly one kind.
  ///
  /// Null while the filter holds several kinds or none at all; the count then
  /// speaks of songs.
  final ContentKind? kind;

  /// Whether the window is narrow enough to spend its width on the list.
  final bool compact;

  /// Whether the search row stands open; the icon then offers to close it.
  final bool searchOpen;

  /// Opens and closes the search row of the page.
  final VoidCallback? onSearch;

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
    required this.count,
    required this.kind,
    required this.compact,
    required this.searchOpen,
    required this.onSearch,
    required this.onAddAll,
    required this.onScan,
    required this.scanning,
    required this.onSearchOnline,
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
    final countStyle = CompactTypography.mono(
      theme.colorScheme.onSurfaceVariant,
      size: CompactTypeScale.mark,
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
                treeExpanded ? Icons.menu_open_rounded : Icons.menu_rounded,
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
          if (compact) ...[
            const SizedBox(width: CompactTokens.space8),
            // 只留一个数：列表现在有多少条。页头原来的「5,121 项内容」和
            // 工具栏的「2,696 首」并排摆着，读者分不清哪个是重点。
            Expanded(
              child: Text(
                libraryCountLabel(context, count: count, kind: kind),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: countStyle,
              ),
            ),
            TuneTooltip(
              message: context.loc.search,
              child: IconButton(
                key: const ValueKey('library-search-toggle'),
                onPressed: onSearch,
                icon: Icon(
                  searchOpen ? Icons.search_off_rounded : Icons.search_rounded,
                  size: CompactTokens.icon18,
                ),
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(CompactTokens.controlDefault),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(width: CompactTokens.space12),
            Expanded(
              child: Text(
                summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: countStyle,
              ),
            ),
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
          ],
          _moreMenu(context),
        ],
      ),
    );
  }

  /// The page entries that do not change how the list is read.
  ///
  /// In a narrow window the two outlined buttons live here instead of taking
  /// the width the count needs.
  Widget _moreMenu(BuildContext context) {
    return TuneTooltip(
      message: context.loc.libraryMoreActions,
      child: PopupMenuButton<String>(
        key: const ValueKey('library-more'),
        icon: const Icon(Icons.more_horiz),
        onSelected: (action) {
          switch (action) {
            case 'albums':
              onAlbums?.call();
            case 'online':
              onSearchOnline?.call();
            case 'scan':
              onScan();
            case 'addAll':
              onAddAll?.call();
          }
        },
        itemBuilder: (context) => [
          if (compact && onAlbums != null)
            PopupMenuItem(
              key: const ValueKey('library-more-albums'),
              value: 'albums',
              child: _menuEntry(
                icon: Icons.grid_view_rounded,
                label: context.loc.libraryViewAlbums,
                active: albumsActive,
              ),
            ),
          if (compact && onSearchOnline != null)
            PopupMenuItem(
              key: const ValueKey('library-more-online'),
              value: 'online',
              child: _menuEntry(
                icon: Icons.travel_explore_rounded,
                label: context.loc.searchOnlineTitle,
              ),
            ),
          PopupMenuItem(
            value: 'scan',
            enabled: !scanning,
            child: _menuEntry(
              icon: scanning
                  ? Icons.hourglass_top_rounded
                  : Icons.refresh_rounded,
              label: context.loc.libraryScanAllSources,
            ),
          ),
          PopupMenuItem(
            value: 'addAll',
            enabled: onAddAll != null,
            child: _menuEntry(
              icon: Icons.playlist_add_rounded,
              label: context.loc.libraryAddAllToQueue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuEntry({
    required IconData icon,
    required String label,
    bool active = false,
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: CompactTokens.icon16),
      title: Text(label),
      trailing: active
          ? const Icon(Icons.check_rounded, size: CompactTokens.icon16)
          : null,
    );
  }

  /// The look both page-wide entries share: outlined, and tinted while it is
  /// the one the page is showing.
  ButtonStyle _scopeStyle(ThemeData theme, bool active) =>
      OutlinedButton.styleFrom(
        minimumSize: const Size(0, CompactTokens.controlDefault),
        padding: const EdgeInsets.symmetric(horizontal: CompactTokens.space12),
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
