import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.spacing32),
            decoration: BoxDecoration(
              color: isDark
                  ? AppDesignSystem.neutral800.withValues(alpha: 0.5)
                  : AppDesignSystem.neutral100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: AppDesignSystem.iconSize56,
              color: isDark ? AppDesignSystem.neutral500 : AppDesignSystem.neutral400,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing24),
          Text(
            title,
            style: AppDesignSystem.textTheme.titleLarge?.copyWith(
              fontWeight: AppDesignSystem.fontWeightSemiBold,
              color: isDark ? AppDesignSystem.neutral100 : AppDesignSystem.neutral900,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppDesignSystem.spacing8),
            Text(
              subtitle!,
              style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppDesignSystem.spacing32),
            action!,
          ],
        ],
      ),
    );
  }
}
