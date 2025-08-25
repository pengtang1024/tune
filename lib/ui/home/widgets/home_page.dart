import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/player/states/player_state.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/widgets/music_card_widget.dart';

/// 现代化的首页组件
/// 展示欢迎信息、快速操作和最近播放的音乐
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    final playerState = ref.watch(playerStateNotifierProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 内容部分
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 欢迎区域
                  _WelcomeSection(playerState: playerState),
                  
                  const SizedBox(height: 24),
                  
                  // 快速操作
                  _QuickActionsSection(),
                  
                  const SizedBox(height: 24),
                  
                  // 最近播放
                  _RecentSection(),
                  
                  const SizedBox(height: 24),
                  
                  // 我的音乐库概览
                  _LibraryOverviewSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 欢迎区域组件
class _WelcomeSection extends ConsumerWidget {
  final PlayerState playerState;

  const _WelcomeSection({required this.playerState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    final currentTime = DateTime.now();
    String greeting;
    
    if (currentTime.hour < 12) {
      greeting = loc.good_morning;
    } else if (currentTime.hour < 18) {
      greeting = loc.good_afternoon;
    } else {
      greeting = loc.good_evening;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,\n${loc.welcome_to_tune}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (playerState.currentSong != null) ...[
              Text(
                loc.now_playing,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    image: playerState.currentSong?.albumArt != null 
                      ? DecorationImage(
                          image: NetworkImage(playerState.currentSong!.albumArt!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  ),
                  child: playerState.currentSong?.albumArt == null
                      ? Icon(
                          Icons.music_note,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        )
                      : null,
                ),
                title: Text(
                  playerState.currentSong!.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${playerState.currentSong!.artist} - ${playerState.currentSong!.album}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: Icon(
                    playerState.isPlaying ? Icons.pause_circle : Icons.play_circle,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    // TODO: 切换播放状态
                  },
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.no_song_playing,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: 导航到音乐库
                      },
                      child: Text(loc.play),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 快速操作组件
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

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
                  label: loc.radio,
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
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// 最近播放组件
class _RecentSection extends ConsumerWidget {
  const _RecentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    // TODO: 实际获取最近播放的歌曲
    final List<Song> songs = [];

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

/// 音乐库概览组件
class _LibraryOverviewSection extends ConsumerWidget {
  const _LibraryOverviewSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    // TODO: 实际获取音乐库统计信息
    final int songCount = 0;
    final int albumCount = 0;
    final int artistCount = 0;

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
            child: Row(
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
            ),
          ),
        ),
      ],
    );
  }
}

/// 音乐库统计项
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
          '$count',
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