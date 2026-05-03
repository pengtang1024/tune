import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快速访问',
          style: AppDesignSystem.textTheme.titleLarge?.copyWith(
            fontWeight: AppDesignSystem.fontWeightBold,
            color: isDark ? AppDesignSystem.neutral100 : AppDesignSystem.neutral900,
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.library_music_rounded,
                title: '音乐库',
                subtitle: '管理本地音乐',
                color: AppDesignSystem.primary,
                onTap: () => context.go('/library'),
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacing16),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.play_circle_rounded,
                title: '播放器',
                subtitle: '查看播放内容',
                color: AppDesignSystem.secondary,
                onTap: () => context.go('/player'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ModernCard(
      padding: const EdgeInsets.all(AppDesignSystem.spacing20),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.spacing12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppDesignSystem.borderRadius12,
            ),
            child: Icon(
              icon,
              color: color,
              size: AppDesignSystem.iconSize32,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing16),
          Text(
            title,
            style: AppDesignSystem.textTheme.titleMedium?.copyWith(
              fontWeight: AppDesignSystem.fontWeightSemiBold,
              color: isDark ? AppDesignSystem.neutral100 : AppDesignSystem.neutral900,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing4),
          Text(
            subtitle,
            style: AppDesignSystem.textTheme.bodySmall?.copyWith(
              color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}
