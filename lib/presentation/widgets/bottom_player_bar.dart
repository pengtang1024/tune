import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/presentation/bloc/player/player_bloc.dart';
import 'package:tune/presentation/bloc/player/player_state.dart';
import 'package:tune/presentation/bloc/player/player_event.dart';
import 'package:auto_route/auto_route.dart';
import 'package:tune/core/routes/app_router.dart';

/// 底部播放栏组件
///
/// 显示当前播放的歌曲信息和控制按钮，固定在屏幕底部。
/// 当有歌曲播放时显示歌曲信息，没有歌曲时显示提示信息。
class BottomPlayerBar extends StatelessWidget {
  /// 创建底部播放栏组件实例
  const BottomPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        if (state is PlayerPlaying || state is PlayerPaused) {
          final song = state is PlayerPlaying ? state.song : (state as PlayerPaused).song;
          final isPlaying = state is PlayerPlaying;
          return Container(
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1), // 使用withValues替代withOpacity
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 专辑封面
                Container(
                  width: 60,
                  height: 60,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.music_note),
                ),
                // 歌曲信息
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SongTitle(title: song.title),
                        _SongArtist(artist: song.artist),
                      ],
                    ),
                  ),
                ),
                // 播放控制按钮
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  onPressed: () {
                    context.read<PlayerBloc>().add(TogglePlayPauseEvent());
                  },
                ),
                // 跳转到播放页面的按钮
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () {
                    context.pushRoute(PlayerRoute());
                  },
                ),
              ],
            ),
          );
        }
        // 如果没有正在播放的歌曲，则显示空容器
        return const SizedBox.shrink();
      },
    );
  }
}

class _SongTitle extends StatelessWidget {
  final String title;

  const _SongTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SongArtist extends StatelessWidget {
  final String artist;

  const _SongArtist({required this.artist});

  @override
  Widget build(BuildContext context) {
    return Text(
      artist,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).textTheme.bodySmall!.color,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}