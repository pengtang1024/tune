import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/widgets/music_card_widget.dart';

/// 最近播放组件
/// 展示最近播放的歌曲列表
class RecentSection extends ConsumerWidget {
  const RecentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    // 获取播放历史
    final playerNotifier = ref.watch(playerStateNotifierProvider.notifier);
    // 从播放器状态中获取最近播放的歌曲
    final List<Song> songs = playerNotifier.getPlayHistory();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.recently_played,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                // TODO: 查看全部最近播放
              },
              child: Text(loc.see_all),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (songs.isEmpty) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.no_recent_songs,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: songs.take(3).map((song) {
                return MusicCardWidget(
                  song: song,
                  onTap: () {
                    // 播放歌曲
                    // 设置播放列表并播放选中的歌曲
                    final index = songs.indexOf(song);
                    playerNotifier.setPlaylist(songs, index);
                    playerNotifier.playSong(song);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}