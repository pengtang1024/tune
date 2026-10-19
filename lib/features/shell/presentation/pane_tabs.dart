import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/theme/compact_tokens.dart';

class PaneTabs extends StatelessWidget {
  final String currentPath;

  const PaneTabs({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: CompactTokens.tabsHeight,
      padding: const EdgeInsets.symmetric(horizontal: CompactTokens.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          _PaneTab(
            label: '音乐库',
            selected: currentPath == '/library',
            onTap: () => context.go('/library'),
          ),
          const SizedBox(width: CompactTokens.space20),
          _PaneTab(
            label: '播放队列',
            selected: currentPath == '/queue',
            onTap: () => context.go('/queue'),
          ),
        ],
      ),
    );
  }
}

class _PaneTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaneTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: CompactTokens.borderRadius6,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CompactTokens.space4,
            vertical: CompactTokens.space6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: CompactTokens.space6),
              AnimatedContainer(
                duration: CompactTokens.fastMotion,
                width: selected ? 18 : 0,
                height: 2,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
