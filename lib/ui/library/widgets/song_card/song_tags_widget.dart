import 'package:flutter/material.dart';
import 'package:tune/domain/models/song.dart';

class SongTagsWidget extends StatelessWidget {
  final Song song;

  const SongTagsWidget({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final tags = _buildTags();

    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 2,
      children: tags,
    );
  }

  List<Widget> _buildTags() {
    final List<Widget> tags = [];

    // 年份标签
    if (song.year != null && song.year != 0) {
      tags.add(_buildTag(
        text: song.year.toString(),
        bgColor: Colors.green.withValues(alpha: 0.1),
        textColor: Colors.green,
      ));
    }

    // 流派标签
    if (song.genre != null && song.genre!.isNotEmpty) {
      tags.add(_buildTag(
        text: song.genre!,
        bgColor: Colors.purple.withValues(alpha: 0.1),
        textColor: Colors.purple,
      ));
    }

    // 比特率标签
    if (song.bitrate != null && song.bitrate != 0) {
      tags.add(_buildTag(
        text: '${song.bitrate}kbps',
        bgColor: Colors.blue.withValues(alpha: 0.1),
        textColor: Colors.blue,
      ));
    }

    // 采样率标签
    if (song.sampleRate != null && song.sampleRate != 0) {
      tags.add(_buildTag(
        text: '${song.sampleRate}Hz',
        bgColor: Colors.orange.withValues(alpha: 0.1),
        textColor: Colors.orange,
      ));
    }

    // 音轨号标签
    if (song.trackNumber != null && song.trackNumber != 0) {
      tags.add(_buildTag(
        text: '#${song.trackNumber}',
        bgColor: Colors.indigo.withValues(alpha: 0.1),
        textColor: Colors.indigo,
      ));
    }

    // 光盘号标签
    if (song.discNumber != null && song.discNumber != 0) {
      tags.add(_buildTag(
        text: 'Disc ${song.discNumber}',
        bgColor: Colors.pink.withValues(alpha: 0.1),
        textColor: Colors.pink,
      ));
    }

    // 文件大小标签
    if (song.size != null && song.size != 0) {
      tags.add(_buildTag(
        text: _formatFileSize(song.size!),
        bgColor: Colors.teal.withValues(alpha: 0.1),
        textColor: Colors.teal,
      ));
    }

    // 收藏标签
    if (song.isFavorite) {
      tags.add(_buildTag(
        text: '♥',
          bgColor: Colors.red.withValues(alpha: 0.1),
          textColor: Colors.red,
      ));
    }

    return tags;
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 构建通用标签组件
  Widget _buildTag(
      {required String text,
      required Color bgColor,
      required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
        ),
      ),
    );
  }
}