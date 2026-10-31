import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/library/presentation/library_view_mode.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The two ways to read the library: as songs or as albums.
///
/// The switch sits next to the title of the page because it changes what
/// the page is, not what the search finds. A reader who is looking for one
/// track keeps the table; a reader who is browsing keeps the covers.
class LibraryViewSwitch extends StatelessWidget {
  final LibraryViewMode view;
  final ValueChanged<LibraryViewMode> onChanged;

  const LibraryViewSwitch({
    super.key,
    required this.view,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: CompactTokens.controlDefault,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: CompactTokens.borderRadius8,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewButton(
            icon: Icons.view_list_rounded,
            tooltip: context.loc.libraryViewSongs,
            selected: view == LibraryViewMode.songs,
            onPressed: () => onChanged(LibraryViewMode.songs),
          ),
          _ViewButton(
            icon: Icons.grid_view_rounded,
            tooltip: context.loc.libraryViewAlbums,
            selected: view == LibraryViewMode.albums,
            onPressed: () => onChanged(LibraryViewMode.albums),
          ),
        ],
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  const _ViewButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TuneTooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: CompactTokens.icon16),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(
          width: CompactTokens.controlSmall,
          height: CompactTokens.controlSmall,
        ),
        style: IconButton.styleFrom(
          foregroundColor: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          backgroundColor: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
