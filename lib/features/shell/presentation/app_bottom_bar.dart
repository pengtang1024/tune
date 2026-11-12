import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';

/// The navigation of the shell on a touch screen.
///
/// A narrow window on the desktop keeps the rail: a mouse reaches it faster
/// than a bar. A phone has no pointer, so the five pages sit under the thumb,
/// in the same order as the rail.
class AppBottomBar extends StatelessWidget {
  final String currentPath;

  /// Called before the bar goes to [path], so the shell can close its panel.
  final VoidCallback? onNavigate;

  const AppBottomBar({super.key, required this.currentPath, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      _BottomDestination(
        icon: Icons.explore_rounded,
        label: context.loc.sidebarDiscover,
        path: '/discover',
      ),
      _BottomDestination(
        icon: Icons.library_music_rounded,
        label: context.loc.libraryTitle,
        path: '/library',
      ),
      _BottomDestination(
        icon: Icons.favorite_rounded,
        label: context.loc.favoritesTitle,
        path: '/favorites',
      ),
      _BottomDestination(
        icon: Icons.podcasts_rounded,
        label: context.loc.sourcesTitle,
        path: '/sources',
      ),
      _BottomDestination(
        icon: Icons.tune_rounded,
        label: context.loc.settingsTitle,
        path: '/settings',
      ),
    ];

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Container(
          height: CompactTokens.bottomBarHeight,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              for (final item in items)
                Expanded(
                  child: _BottomItem(
                    key: ValueKey('bottom-bar-${item.path}'),
                    item: item,
                    selected: currentPath == item.path,
                    onNavigate: onNavigate,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomDestination {
  final IconData icon;
  final String label;
  final String path;

  const _BottomDestination({
    required this.icon,
    required this.label,
    required this.path,
  });
}

class _BottomItem extends StatelessWidget {
  final _BottomDestination item;
  final bool selected;
  final VoidCallback? onNavigate;

  const _BottomItem({
    super.key,
    required this.item,
    required this.selected,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: () {
        onNavigate?.call();
        context.go(item.path);
      },
      child: Semantics(
        selected: selected,
        button: true,
        label: item.label,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: CompactTokens.icon20, color: color),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
