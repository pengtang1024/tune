import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class ScanResultsHeaderWidget extends StatelessWidget {
  final int scannedCount;
  const ScanResultsHeaderWidget({super.key, this.scannedCount = 0});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${context.loc.songs} ($scannedCount ${context.loc.songs})',
      style: AppDesignSystem.textTheme.headlineSmall?.copyWith(
        fontWeight: AppDesignSystem.fontWeightBold,
      ),
    );
  }
}
