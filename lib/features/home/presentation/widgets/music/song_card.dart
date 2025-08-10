import 'package:flutter/material.dart';
import 'package:tune/domain/entities/song.dart';

/// 歌曲卡片（全平台复用）
class SongCard extends StatelessWidget {
  /// 歌曲信息
  final Song song;

  /// 点击回调
  final VoidCallback? onTap;

  /// 构造函数
  const SongCard({
    super.key,
    required this.song,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(song.title),
        subtitle: Text('${song.artist} - ${song.album}'),
        trailing: IconButton(
          icon: Icon(
            song.isFavorite ? Icons.favorite : Icons.favorite_border,
          ),
          onPressed: () {
            // TODO: 实现收藏切换逻辑
          },
        ),
        onTap: onTap,
      ),
    );
  }
}