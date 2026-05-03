import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? AppDesignSystem.primary;

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppDesignSystem.spacing10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppDesignSystem.borderRadius12,
            ),
            child: Icon(
              icon,
              color: color,
              size: AppDesignSystem.iconSize24,
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppDesignSystem.textTheme.titleSmall?.copyWith(
                    fontWeight: AppDesignSystem.fontWeightSemiBold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppDesignSystem.spacing4),
                  Text(
                    subtitle!,
                    style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppDesignSystem.spacing12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
