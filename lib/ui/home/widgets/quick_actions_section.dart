import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/extension/localizations_extension.dart';

/// 快速操作组件
/// 展示常用功能的快捷入口
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.quick_actions,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickActionButton(
                  icon: Icons.music_note_outlined,
                  label: loc.my_songs,
                  onTap: () {
                    // 导航到我的音乐
                    context.go('/library/songs');
                  },
                ),
                _QuickActionButton(
                  icon: Icons.favorite_border,
                  label: loc.favorites,
                  onTap: () {
                    // 导航到收藏
                    context.go('/library/favorites');
                  },
                ),
                _QuickActionButton(
                  icon: Icons.playlist_play,
                  label: loc.playlists,
                  onTap: () {
                    // 导航到播放列表
                    context.go('/library/playlists');
                  },
                ),
                _QuickActionButton(
                  icon: Icons.radio,
                  label: loc.radio,
                  onTap: () {
                    // 导航到电台
                    context.go('/radio');
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
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(30),
          ),
          child: IconButton(
            iconSize: 30,
            icon: Icon(icon),
            onPressed: onTap,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}