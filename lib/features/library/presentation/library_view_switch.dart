import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/library/domain/library_layout.dart';
import 'package:tune/features/library/presentation/library_view_mode.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The ways to read the library that this kind of content offers.
///
/// The switch sits next to the title of the page because it changes what
/// the page is, not what the search finds. A reader who is looking for one
/// track keeps the table; a reader who is browsing keeps the covers.
///
/// 哪几档出现由内容的分类决定（`library_layout.dart`）：播客只有「节目 / 单集」，
/// 电台没有专辑墙，音效只有平铺列表——把不属于这一类的按钮摆出来，读者要自己
/// 试一遍才知道哪个没用。
class LibraryViewSwitch extends StatelessWidget {
  final LibraryViewMode view;
  final List<LibraryViewMode> views;
  final LibraryGroupingLabel? groupingLabel;
  final ValueChanged<LibraryViewMode> onChanged;

  const LibraryViewSwitch({
    super.key,
    required this.view,
    this.views = LibraryViewMode.values,
    this.groupingLabel,
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
          for (final option in views)
            _ViewButton(
              icon: _iconOf(option),
              tooltip: _labelOf(context, option, groupingLabel),
              selected: view == option,
              onPressed: () => onChanged(option),
            ),
        ],
      ),
    );
  }
}

/// 一档视图的图标与名字；「专辑」这一档随内容分类换成「节目」「书」。
IconData _iconOf(LibraryViewMode mode) => switch (mode) {
  LibraryViewMode.songs => Icons.view_list_rounded,
  LibraryViewMode.columns => Icons.view_column_rounded,
  LibraryViewMode.categories => Icons.category_rounded,
  LibraryViewMode.albums => Icons.grid_view_rounded,
  LibraryViewMode.collections => Icons.collections_bookmark_rounded,
};

String _labelOf(
  BuildContext context,
  LibraryViewMode mode,
  LibraryGroupingLabel? groupingLabel,
) =>
    switch (mode) {
      LibraryViewMode.songs => context.loc.libraryViewSongs,
      LibraryViewMode.columns => context.loc.libraryViewColumns,
      LibraryViewMode.categories => context.loc.libraryViewCategories,
      LibraryViewMode.albums => switch (groupingLabel) {
        LibraryGroupingLabel.show => context.loc.libraryViewShows,
        LibraryGroupingLabel.book => context.loc.libraryViewBooks,
        _ => context.loc.libraryViewAlbums,
      },
      LibraryViewMode.collections => context.loc.libraryViewCollections,
    };

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
