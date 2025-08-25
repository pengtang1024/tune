import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';

/// 快速操作区域组件
/// 提供对主要功能的快速访问
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions', // 使用硬编码字符串替代不存在的本地化字符串
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
                _QuickActionButton(
                  icon: Icons.music_note,
                  label: loc.songs,
                  onTap: () {
                    // TODO: 导航到我的音乐
                  },
                ),
                _QuickActionButton(
                  icon: Icons.favorite_border,
                  label: loc.favorites,
                  onTap: () {
                    // TODO: 导航到收藏
                  },
                ),
                _QuickActionButton(
                  icon: Icons.playlist_play,
                  label: loc.playlists,
                  onTap: () {
                    // TODO: 导航到播放列表
                  },
                ),
                _QuickActionButton(
                  icon: Icons.radio,
                  label: 'Radio', // 使用硬编码字符串替代不存在的本地化字符串
                  onTap: () {
                    // TODO: 导航到电台
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 快速操作按钮
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          iconSize: 32,
          icon: Icon(icon),
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}