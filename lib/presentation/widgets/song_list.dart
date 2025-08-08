import 'package:flutter/material.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/l10n/app_localizations.dart'; // 使用生成的本地化文件

class SongList extends StatelessWidget {
  final List<Song> songs;
  /// 歌曲项点击回调
  final Function(Song song) onSongTap;

  /// 创建歌曲列表组件实例
  /// 
  /// [songs] 要显示的歌曲列表
  /// [onSongTap] 歌曲项点击回调函数
  const SongList({super.key, required this.songs, required this.onSongTap});

  @override
  Widget build(BuildContext context) {
    // 使用Flutter官方生成的本地化机制
    final localizations = AppLocalizations.of(context)!;
    
    // 如果歌曲列表为空，则显示提示信息
    if (songs.isEmpty) {
      return Center(
        child: Text(localizations.song_list_no_songs),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.music_note),
          ),
          title: Text(song.title),
          // 歌手和专辑信息
          subtitle: Text('${song.artist} - ${song.album}'),
          // 点击事件处理
          onTap: () => onSongTap(song),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}