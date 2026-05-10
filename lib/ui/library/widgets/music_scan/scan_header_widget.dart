import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class ScanHeaderWidget extends StatelessWidget {
  const ScanHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scan Local Music',
          style: AppDesignSystem.textTheme.headlineSmall?.copyWith(
            fontWeight: AppDesignSystem.fontWeightBold,
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing8),
        Text(
          'Scan your local music library, organize files and extract metadata',
          style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
            color: AppDesignSystem.neutral500,
          ),
        ),
      ],
    );
  }
}
