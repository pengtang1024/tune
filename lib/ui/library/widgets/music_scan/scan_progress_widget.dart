import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class ScanProgressWidget extends StatelessWidget {
  final double progress;
  const ScanProgressWidget({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDesignSystem.spacing8),
      child: ClipRRect(
        borderRadius: AppDesignSystem.borderRadius4,
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: AppDesignSystem.neutral200,
          valueColor: const AlwaysStoppedAnimation(AppDesignSystem.primary),
        ),
      ),
    );
  }
}
