import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
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

  final VoidCallback onSearchOnline;

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
}
