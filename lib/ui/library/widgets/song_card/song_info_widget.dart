import 'package:flutter/material.dart';
import 'package:tune/domain/models/song.dart';

class SongInfoWidget extends StatelessWidget {
  final Song song;
  final int? index; // 添加序号参数

  const SongInfoWidget({super.key, required this.song, this.index});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 歌曲标题和时长 (在同一行)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 显示序号（如果提供）
            if (index != null)
              Text(
                '${index! + 1}.', // 序号从1开始
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            if (index != null)
              const SizedBox(width: 6),
            Expanded(
              child: Text(
                song.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // 减小字体大小
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(width: 6),
            // 时长
            Text(
              _formatDuration(song.duration),
              style: const TextStyle(
                fontSize: 12, // 减小字体大小
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2), // 减小间距
        // 艺术家和专辑 (在同一行)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '${song.artist} · ${song.album}',
                style: const TextStyle(
                  fontSize: 11, // 减小字体大小
                  color: Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 格式化歌曲时长
  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}