import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:tune/app/router/app_router.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/features/home/presentation/widgets/shared/quick_action_card.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : constraints.maxWidth > 800 ? 3 : 2;

        // 在桌面端使用水平滚动布局，在移动端使用网格布局
        if (crossAxisCount > 2) {
          // 桌面端 - 使用水平滚动布局以节省垂直空间
          return SizedBox(
            height: 60, // 减小高度使组件更加紧凑
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                QuickActionCard(
                  icon: Icons.music_note,
                  title: localizations.library_title,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  onTap: () {
                    context.pushRoute(const MusicLibraryRoute());
                  },
                  isDesktop: true,
                ),
                const SizedBox(width: 8),
                QuickActionCard(
                  icon: Icons.favorite,
                  title: localizations.favorites,
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  onTap: () {
                    // TODO: 导航到收藏页面
                  },
                  isDesktop: true,
                ),
                const SizedBox(width: 8),
                QuickActionCard(
                  icon: Icons.playlist_play,
                  title: localizations.playlists,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  onTap: () {
                    // TODO: 导航到播放列表页面
                  },
                  isDesktop: true,
                ),
                const SizedBox(width: 8),
                QuickActionCard(
                  icon: Icons.history,
                  title: localizations.recently_played,
                  color: Theme.of(context).colorScheme.errorContainer,
                  onTap: () {
                    // TODO: 导航到最近播放页面
                  },
                  isDesktop: true,
                ),
                const SizedBox(width: 8),
                QuickActionCard(
                  icon: Icons.find_in_page,
                  title: localizations.scan_local_music,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  onTap: () {
                    context.pushRoute(const MusicScanRoute());
                  },
                  isDesktop: true,
                ),
                const SizedBox(width: 8), // 添加末尾间距
              ],
            ),
          );
        } else {
          // 移动端 - 使用网格布局
          return SizedBox(
            height: 120.0, // 减小移动端高度
            child: GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8, // 统一间距
              mainAxisSpacing: 8, // 统一间距
              physics: const NeverScrollableScrollPhysics(),
              children: [
                QuickActionCard(
                  icon: Icons.music_note,
                  title: localizations.library_title,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  onTap: () {
                    context.pushRoute(const MusicLibraryRoute());
                  },
                ),
                QuickActionCard(
                  icon: Icons.favorite,
                  title: localizations.favorites,
                  color: Theme.of(context).colorScheme.errorContainer,
                  onTap: () {
                    // TODO: 导航到收藏页面
                  },
                ),
                QuickActionCard(
                  icon: Icons.playlist_play,
                  title: localizations.playlists,
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  onTap: () {
                    // TODO: 导航到播放列表页面
                  },
                ),
                QuickActionCard(
                  icon: Icons.history,
                  title: localizations.recently_played,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  onTap: () {
                    // TODO: 导航到最近播放页面
                  },
                ),
                QuickActionCard(
                  icon: Icons.find_in_page,
                  title: localizations.scan_local_music,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  onTap: () {
                    context.pushRoute(const MusicScanRoute());
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
