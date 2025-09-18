import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/player/providers/player_providers.dart';

/// 播放历史记录组件
class PlayerHistory extends ConsumerWidget {
  const PlayerHistory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final loc = context.loc;

    // 获取最近播放的歌曲历史
    final List<Song> history = playerNotifier.getPlayHistory().take(5).toList();

    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 160, // 增加容器高度以解决溢出问题
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.recently_played, // 使用本地化文本
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: history.length,
              itemBuilder: (context, index) {
                final song = history[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Icon(
                              Icons.music_note,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 6), // 增加间距
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  (constraints.maxHeight - 60) / 2, // 调整高度计算
                            ),
                            child: Text(
                              song.title,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4), // 调整间距
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  (constraints.maxHeight - 60) / 2, // 调整高度计算
                            ),
                            child: Text(
                              song.artist,
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
