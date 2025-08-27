import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/repositories/music_repository.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/providers/music_providers.dart';

/// 音乐库概览组件
/// 展示音乐库的统计信息
class LibraryOverviewSection extends ConsumerWidget {
  const LibraryOverviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    // 实际获取音乐库统计信息
    final musicRepository = ref.watch(musicRepositoryProvider);
    final AsyncValue<List<Song>> songsAsync = ref.watch(_songsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.music_library,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: songsAsync.when(
              data: (songs) {
                // 简单统计 - 实际项目中可能需要更复杂的统计逻辑
                final songCount = songs.length;
                final albumCount = songs.map((s) => s.album ?? '').toSet().length;
                final artistCount = songs.map((s) => s.artist ?? '').toSet().length;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _LibraryStatItem(
                      icon: Icons.music_note,
                      count: songCount,
                      label: loc.songs,
                    ),
                    _LibraryStatItem(
                      icon: Icons.album,
                      count: albumCount,
                      label: loc.albums,
                    ),
                    _LibraryStatItem(
                      icon: Icons.person,
                      count: artistCount,
                      label: loc.artists,
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 音乐列表提供者
final _songsProvider = FutureProvider<List<Song>>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  return repository.getAllSongs();
});

/// 音乐库统计项
/// 显示单个统计信息，如歌曲数量、专辑数量等
class _LibraryStatItem extends StatelessWidget {
  /// 将数字格式化为更易读的形式
  /// 例如：1000 -> 1K, 1500000 -> 1.5M
  String countFormatter(int count) {
    if (count < 1000) {
      return '$count';
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
  final IconData icon;
  final int count;
  final String label;

  const _LibraryStatItem({
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(
            icon,
            size: 32,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          countFormatter(count),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}