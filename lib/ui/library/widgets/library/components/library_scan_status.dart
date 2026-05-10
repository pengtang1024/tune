import 'package:flutter/material.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class LibraryScanStatus extends StatelessWidget {
  final LibraryState state;
  const LibraryScanStatus({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.scanStatus == ScanStatus.idle || state.scanStatus == ScanStatus.completed) {
      return const SizedBox.shrink();
    }

    final isError = state.scanStatus == ScanStatus.error;
    final color = isError ? AppDesignSystem.error : AppDesignSystem.primary;

    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing12),
      margin: const EdgeInsets.only(bottom: AppDesignSystem.spacing16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppDesignSystem.borderRadius12,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          if (state.scanStatus == ScanStatus.scanning) ...[
            SizedBox(
              width: AppDesignSystem.iconSize20, height: AppDesignSystem.iconSize20,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(color)),
            ),
            const SizedBox(width: AppDesignSystem.spacing12),
          ] else if (isError) ...[
            Icon(Icons.error_outline, color: color, size: AppDesignSystem.iconSize20),
            const SizedBox(width: AppDesignSystem.spacing12),
          ],
          Expanded(
            child: Text(
              state.statusMessage,
              style: AppDesignSystem.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
