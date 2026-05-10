import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class UserInfoWidget extends StatelessWidget {
  const UserInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: isDark ? AppDesignSystem.neutral700 : AppDesignSystem.neutral200,
          child: Icon(Icons.person, size: AppDesignSystem.iconSize20, color: AppDesignSystem.neutral400),
        ),
        const SizedBox(width: AppDesignSystem.spacing10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'User',
                style: AppDesignSystem.textTheme.labelMedium?.copyWith(
                  fontWeight: AppDesignSystem.fontWeightSemiBold,
                ),
              ),
              Text(
                'user@example.com',
                style: AppDesignSystem.textTheme.labelSmall?.copyWith(
                  color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
