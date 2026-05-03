import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/providers/music_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

/// 音乐库概览组件
/// 展示音乐库的统计信息
class LibraryOverviewSection extends ConsumerWidget {
  const LibraryOverviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    // 实际获取音乐库统计信息
    final AsyncValue<List<Song>> songsAsync = ref.watch(_songsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.music_library,
          style: AppDesignSystem.textTheme.titleLarge?.copyWith(
                fontWeight: AppDesignSystem.fontWeightBold,
              ),
        ),
        const SizedBox(height: AppDesignSystem.spacing12),
        ModernCard(
          padding: const EdgeInsets.all(AppDesignSystem.spacing20),
          child: songsAsync.when(
            data: (songs) {
              // 简单统计 - 实际项目中可能需要更复杂的统计逻辑
              final songCount = songs.length;
              final albumCount = songs.map((s) => s.album).where((album) => album.isNotEmpty).toSet().length;
              final artistCount = songs.map((s) => s.artist).where((artist) => artist.isNotEmpty).toSet().length;
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _LibraryStatItem(
                    icon: Icons.music_note,
                    count: songCount,
                    label: loc.songs,
                    color: AppDesignSystem.primary,
                  ),
                  _LibraryStatItem(
                    icon: Icons.album,
                    count: albumCount,
                    label: loc.albums,
                    color: AppDesignSystem.secondary,
                  ),
                  _LibraryStatItem(
                    icon: Icons.person,
                    count: artistCount,
                    label: loc.artists,
                    color: AppDesignSystem.tertiary,
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
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
  final Color color;

  const _LibraryStatItem({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDesignSystem.spacing12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppDesignSystem.borderRadius16,
          ),
          child: Icon(
            icon,
            size: AppDesignSystem.iconSize32,
            color: color,
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing12),
        Text(
          countFormatter(count),
          style: AppDesignSystem.textTheme.titleMedium?.copyWith(
            fontWeight: AppDesignSystem.fontWeightBold,
          ),
        ),
        Text(
          label,
          style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}