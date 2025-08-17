import 'package:flutter/material.dart';
import 'package:tune/core/extension/theme_extension.dart';
import 'package:tune/domain/models/song.dart';

/// 歌曲列表项组件
/// 显示单首歌曲的信息
class SongListItemWidget extends StatelessWidget {
  final Song song;
  final String durationText;

  const SongListItemWidget({
    super.key,
    required this.song,
    required this.durationText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: context.theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.music_note,
              color: context.theme.colorScheme.onSurfaceVariant,
            ),
          ),
          title: Text(song.title),
          subtitle: Text('${song.artist ?? '未知艺术家'} · ${song.album ?? '未知专辑'}'),
          trailing: Text(durationText),
        ),
      ),
    );
  }
}