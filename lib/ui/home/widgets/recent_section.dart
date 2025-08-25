import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/widgets/music_card_widget.dart';

/// 最近播放区域组件
/// 展示最近播放的歌曲列表
class RecentSection extends ConsumerWidget {
  const RecentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(libraryStateNotifierProvider).songs;
    final loc = context.loc;

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
              child: Text('See more'), // 使用硬编码字符串替代不存在的本地化字符串
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (songs.isEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(loc.no_songs_found),
            ),
          ),
        ] else ...[
          Card(
            child: Column(
              children: songs.take(3).map((song) {
                return MusicCardWidget(
                  song: song,
                  onTap: () {
                    // TODO: 播放歌曲
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