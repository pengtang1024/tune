import 'package:flutter/material.dart';

/// 歌单网格项（用于首页展示）
class PlaylistGrid extends StatelessWidget {
  /// 标题
  final String title;
  
  /// 副标题
  final String subtitle;
  
  /// 图片URL
  final String imageUrl;

  /// 构造函数
  const PlaylistGrid({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.queue_music,
                size: 48,
                color: Colors.grey[600],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}