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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 根据扫描状态显示不同内容
          if (state.scanStatus == ScanStatus.idle) ...[
            const ScanStatusWidget(statusMessage: '等待开始扫描'),
            const EmptyStateWidget(),
          ] else if (state.scanStatus == ScanStatus.scanning) ...[
            const ScanStatusWidget(statusMessage: '正在扫描'),
            ScanProgressWidget(progress: state.scanProgress),
          ] else if (state.scanStatus == ScanStatus.completed) ...[
            ScanStatusWidget(
              statusMessage: '扫描完成，找到 ${state.foundSongs.length} 首歌曲',
            ),
          ] else if (state.scanStatus == ScanStatus.error) ...[
            const ScanStatusWidget(statusMessage: '扫描出错'),
            ErrorStateWidget(
              errorMessage: state.errorMessage ?? '未知错误',
            ),
          ],
        ],
      ),
    );
  }
}