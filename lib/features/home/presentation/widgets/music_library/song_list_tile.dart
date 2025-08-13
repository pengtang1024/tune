import 'package:flutter/material.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/l10n/app_localizations.dart';

class SongListTile extends StatelessWidget {
  final Song song;

  const SongListTile({super.key, required this.song});

  String _formatDuration(int seconds) {
    final Duration duration = Duration(seconds: seconds);
    final int minutes = duration.inMinutes;
    final int secs = duration.inSeconds.remainder(60);
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(
            Icons.music_note,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  song.album,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    song.genre,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDuration(song.duration),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                song.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: song.isFavorite 
                  ? Theme.of(context).colorScheme.error 
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                // 处理收藏/取消收藏逻辑
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // 显示更多选项菜单
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.play_arrow),
                            title: Text(localizations.play_button),
                            onTap: () {
                              Navigator.pop(context);
                              // 播放歌曲逻辑
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.queue_music),
                            title: Text('${localizations.play_button} ${localizations.next_button.toLowerCase()}'),
                            onTap: () {
                              Navigator.pop(context);
                              // 添加到播放队列逻辑
                            },
                          ),
                          ListTile(
                            leading: Icon(
                              song.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: song.isFavorite 
                                ? Theme.of(context).colorScheme.error 
                                : null,
                            ),
                            title: Text(song.isFavorite 
                              ? '${localizations.favorite_button}d' 
                              : localizations.favorite_button),
                            onTap: () {
                              Navigator.pop(context);
                              // 收藏/取消收藏逻辑
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.album),
                            title: Text('${localizations.artist_title}: ${song.artist}'),
                            onTap: () {
                              Navigator.pop(context);
                              // 跳转到艺术家页面
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.album),
                            title: Text('${localizations.library_albums}: ${song.album}'),
                            onTap: () {
                              Navigator.pop(context);
                              // 跳转到专辑页面
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        onTap: () {
          // 处理点击播放歌曲逻辑
        },
      ),
    );
  }
}
