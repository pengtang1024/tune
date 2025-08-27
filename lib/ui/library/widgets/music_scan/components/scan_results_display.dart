import 'package:flutter/material.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/ui/library/widgets/music_scan/scan_results_header_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/song_list_item_widget.dart';

class ScanResultsDisplay extends StatelessWidget {
  final LibraryState state;
  final VoidCallback onAddToLibrary;
  final VoidCallback onResetScan;
  final Function(Song) onPlaySong;

  const ScanResultsDisplay({
    super.key,
    required this.state,
    required this.onAddToLibrary,
    required this.onResetScan,
    required this.onPlaySong,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScanResultsHeaderWidget(scannedCount: state.foundSongs.length),
          const SizedBox(height: 24),
          
          // 显示扫描结果
          if (state.scanStatus == ScanStatus.completed && state.foundSongs.isNotEmpty) ...[
            Text(
              '找到 ${state.foundSongs.length} 首歌曲',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // 使用ConstrainedBox替代LimitedBox以避免hit test问题
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.foundSongs.length,
                itemBuilder: (context, index) {
                  final song = state.foundSongs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SongListItemWidget(
                      song: song,
                      durationText: _formatDuration(Duration(milliseconds: song.duration)),
                      onPlay: () => onPlaySong(song),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAddToLibrary,
                    child: const Text('添加到音乐库'),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: onResetScan,
                  child: const Text('重新扫描'),
                ),
              ],
            ),
          ] else if (state.scanStatus == ScanStatus.completed) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '未找到任何歌曲',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '请检查扫描路径中是否包含音乐文件',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton(
                onPressed: onResetScan,
                child: const Text('重新扫描'),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}