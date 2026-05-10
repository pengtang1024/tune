import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_interactions.dart';

class CustomPathsHeaderWidget extends StatelessWidget {
  final VoidCallback onAddPath;
  const CustomPathsHeaderWidget({super.key, required this.onAddPath});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Custom Scan Paths',
          style: AppDesignSystem.textTheme.titleLarge?.copyWith(
            fontWeight: AppDesignSystem.fontWeightBold,
          ),
        ),
        AppInteractions.pressableScale(
          scaleValue: 0.9,
          onTap: onAddPath,
          child: Container(
            padding: const EdgeInsets.all(AppDesignSystem.spacing8),
            decoration: BoxDecoration(
              color: AppDesignSystem.primary.withValues(alpha: 0.08),
              borderRadius: AppDesignSystem.borderRadius8,
            ),
            child: const Icon(Icons.add, size: AppDesignSystem.iconSize24, color: AppDesignSystem.primary),
          ),
        ),
      ],
    );
  }
}
