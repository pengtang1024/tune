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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScanResultsHeaderWidget(scannedCount: state.foundSongs.length),
          const SizedBox(height: 16),
          // 显示扫描结果
          if (state.scanStatus == ScanStatus.completed && state.foundSongs.isNotEmpty) ...[
            Text('找到 ${state.foundSongs.length} 首歌曲'),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.foundSongs.length,
              itemBuilder: (context, index) {
                final song = state.foundSongs[index];
                return SongListItemWidget(
                  song: song,
                  durationText: _formatDuration(Duration(milliseconds: song.duration)),
                  onPlay: () => onPlaySong(song),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAddToLibrary,
              child: const Text('添加到音乐库'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onResetScan,
              child: const Text('重新扫描'),
            ),
          ] else if (state.scanStatus == ScanStatus.completed) ...[
            const Text('未找到任何歌曲'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onResetScan,
              child: const Text('重新扫描'),
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