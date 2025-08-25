import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/library/providers/library_providers.dart';

/// 音乐库概览区域组件
/// 展示音乐库的统计数据
class LibraryOverviewSection extends ConsumerWidget {
  const LibraryOverviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(libraryStateNotifierProvider).songs;
    final loc = context.loc;

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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LibraryStatItem(
                  icon: Icons.music_note,
                  count: songs.length,
                  label: loc.songs,
                ),
                _LibraryStatItem(
                  icon: Icons.album,
                  count: songs.map((s) => s.album).toSet().length,
                  label: loc.albums,
                ),
                _LibraryStatItem(
                  icon: Icons.person,
                  count: songs.map((s) => s.artist).toSet().length,
                  label: loc.artists,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 音乐库统计项组件
class _LibraryStatItem extends StatelessWidget {
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
        Icon(icon, size: 32),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(label),
      ],
    );
  }
}