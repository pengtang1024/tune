import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/ui/library/widgets/music_scan/widgets/custom_paths_description_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/widgets/custom_paths_header_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/widgets/custom_paths_scan_button_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/widgets/empty_state_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/widgets/error_state_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/widgets/scan_button_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/widgets/scan_header_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/widgets/scan_progress_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/widgets/scan_results_header_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/widgets/scan_status_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/widgets/song_list_item_widget.dart';

/// 音乐扫描页面
/// 提供音乐文件扫描功能，包括自定义路径管理和扫描结果显示
class MusicScanPage extends ConsumerStatefulWidget {
  const MusicScanPage({super.key});

  @override
  ConsumerState<MusicScanPage> createState() => _MusicScanPageState();
}

class _MusicScanPageState extends ConsumerState<MusicScanPage> {
  @override
  void initState() {
    super.initState();
    // 初始化时开始扫描音乐
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryStateNotifierProvider.notifier).scanMusic();
    });
  }

  @override
  Widget build(BuildContext context) {


    final state = ref.watch(libraryStateNotifierProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScanHeaderWidget(),
            const SizedBox(height: 16),
            ScanStatusWidget(
              statusMessage: state.statusMessage,
              errorMessage: state.errorMessage ?? '',
            ),
            const SizedBox(height: 16),
            if (state.scanStatus == ScanStatus.scanning) ...[
              ScanProgressWidget(
                isScanning: state.scanStatus == ScanStatus.scanning,
                totalCount: 100, // 示例值
                scannedCount: (state.scanProgress * 100).toInt(),
              ),
              const SizedBox(height: 16),
            ],
            ScanButtonWidget(
              isScanning: state.scanStatus == ScanStatus.scanning,
              onPressed: () {
                ref.read(libraryStateNotifierProvider.notifier).scanMusic();
              },
            ),
            const SizedBox(height: 16),
            if (state.errorMessage != null) ...[
              ErrorStateWidget(
                errorMessage: state.errorMessage!,
                onRetry: () {
                  ref.read(libraryStateNotifierProvider.notifier).resetScan();
                  ref.read(libraryStateNotifierProvider.notifier).scanMusic();
                },
              ),
              const SizedBox(height: 16),
            ],
            if (state.foundSongs.isEmpty &&
                state.scanStatus != ScanStatus.scanning &&
                state.errorMessage == null) ...[
              const EmptyStateWidget(),
              const SizedBox(height: 16),
            ],
            if (state.foundSongs.isNotEmpty) ...[
              ScanResultsHeaderWidget(scannedCount: state.foundSongs.length),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: state.foundSongs.length,
                  itemBuilder: (context, index) {
                    final song = state.foundSongs[index];
                    return SongListItemWidget(
                      song: song,
                      durationText: _formatDuration(song.duration),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            CustomPathsHeaderWidget(
              onAddPath: () {
                // TODO: 实现添加自定义路径功能
              },
            ),
            const SizedBox(height: 8),
            const CustomPathsDescriptionWidget(),
            const SizedBox(height: 8),
            const Expanded(
              child: Center(
                child: Text('自定义路径功能将在后续版本中实现'),
              ),
            ),
            const SizedBox(height: 16),
            CustomPathsScanButtonWidget(
              isScanning: state.scanStatus == ScanStatus.scanning,
              hasCustomPaths: false, // 示例值
              onPressed: () {
                // TODO: 实现扫描自定义路径功能
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int durationInMilliseconds) {
    final duration = Duration(milliseconds: durationInMilliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
