import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/ui/library/widgets/music_scan/scan_status_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/scan_progress_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/empty_state_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/error_state_widget.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class ScanStatusDisplay extends ConsumerWidget {
  final LibraryState state;
  const ScanStatusDisplay({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ModernCard(
      padding: const EdgeInsets.all(AppDesignSystem.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '扫描状态',
            style: AppDesignSystem.textTheme.titleMedium?.copyWith(
              fontWeight: AppDesignSystem.fontWeightBold,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing16),
          if (state.scanStatus == ScanStatus.idle) ...[
            const ScanStatusWidget(statusMessage: '等待开始扫描'),
            const SizedBox(height: AppDesignSystem.spacing16),
            const EmptyStateWidget(),
          ] else if (state.scanStatus == ScanStatus.scanning) ...[
            const ScanStatusWidget(statusMessage: '正在扫描...'),
            const SizedBox(height: AppDesignSystem.spacing16),
            ScanProgressWidget(progress: state.scanProgress),
          ] else if (state.scanStatus == ScanStatus.completed) ...[
            ScanStatusWidget(statusMessage: 'Scan complete, found ${state.foundSongs.length} songs'),
          ] else if (state.scanStatus == ScanStatus.error) ...[
            const ScanStatusWidget(statusMessage: '扫描出错'),
            const SizedBox(height: AppDesignSystem.spacing16),
            ErrorStateWidget(errorMessage: state.errorMessage ?? '扫描出错'),
          ],
        ],
      ),
    );
  }
}
