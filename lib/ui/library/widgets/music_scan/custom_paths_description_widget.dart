import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class CustomPathsDescriptionWidget extends StatelessWidget {
  const CustomPathsDescriptionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppDesignSystem.spacing8),
        Text(
          'Add custom folder paths to scan music files from specific locations',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        SizedBox(height: AppDesignSystem.spacing16),
      ],
    );
  }
}
