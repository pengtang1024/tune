import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/ui/library/widgets/music_scan/scan_status_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/scan_progress_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/empty_state_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/error_state_widget.dart';

class ScanStatusDisplay extends ConsumerWidget {
  final LibraryState state;

  const ScanStatusDisplay({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '扫描状态',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          // 根据扫描状态显示不同内容
          if (state.scanStatus == ScanStatus.idle) ...[
            const ScanStatusWidget(statusMessage: '等待开始扫描'),
            const SizedBox(height: 16),
            const EmptyStateWidget(),
          ] else if (state.scanStatus == ScanStatus.scanning) ...[
            const ScanStatusWidget(statusMessage: '正在扫描'),
            const SizedBox(height: 16),
            ScanProgressWidget(progress: state.scanProgress),
          ] else if (state.scanStatus == ScanStatus.completed) ...[
            ScanStatusWidget(
              statusMessage: '扫描完成，找到 ${state.foundSongs.length} 首歌曲',
            ),
          ] else if (state.scanStatus == ScanStatus.error) ...[
            const ScanStatusWidget(statusMessage: '扫描出错'),
            const SizedBox(height: 16),
            ErrorStateWidget(
              errorMessage: state.errorMessage ?? '未知错误',
            ),
          ],
        ],
      ),
    );
  }
}