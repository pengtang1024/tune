import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/theme/compact_tokens.dart';

class AppHeader extends StatelessWidget {
  final String currentPath;

  const AppHeader({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSettings = currentPath == '/settings';

    return Container(
      height: CompactTokens.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: CompactTokens.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: CompactTokens.borderRadius6,
            ),
            child: Icon(
              Icons.music_note_rounded,
              size: CompactTokens.icon14,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: CompactTokens.space8),
          Text(
            'Tune',
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: isSettings ? '返回' : '设置',
            onPressed: () {
              if (!isSettings) {
                context.push('/settings');
                return;
              }
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/library');
              }
            },
            icon: Icon(
              isSettings ? Icons.close_rounded : Icons.settings_outlined,
              size: CompactTokens.icon20,
            ),
            style: IconButton.styleFrom(
              fixedSize: const Size.square(CompactTokens.controlSmall),
              minimumSize: const Size.square(CompactTokens.controlSmall),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
