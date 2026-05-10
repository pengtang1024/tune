import 'package:flutter/material.dart';
import 'package:tune/ui/library/widgets/music_scan/scan_button_widget.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class ScanControlButtons extends StatelessWidget {
  final bool isScanning;
  final bool hasCustomPaths;
  final VoidCallback? onStartScan;

  const ScanControlButtons({
    super.key,
    required this.isScanning,
    required this.hasCustomPaths,
    this.onStartScan,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(AppDesignSystem.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scan Control',
            style: AppDesignSystem.textTheme.titleMedium?.copyWith(fontWeight: AppDesignSystem.fontWeightBold),
          ),
          const SizedBox(height: AppDesignSystem.spacing16),
          Center(
            child: SizedBox(
              width: 200,
              child: ScanButtonWidget(
                onPressed: hasCustomPaths && !isScanning ? onStartScan : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
