import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/features/home/presentation/bloc/player/player_bloc.dart';
import 'package:tune/features/home/presentation/bloc/player/player_state.dart';
import 'package:tune/features/home/presentation/bloc/player/player_event.dart';
import 'package:tune/core/utils/platform_detector.dart';

/// 底部播放控制栏
class BottomPlayerBar extends StatelessWidget {
  /// 构造函数
  const BottomPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        // 只有在有歌曲播放、暂停、缓冲或加载时才显示底部播放栏
        if (state is PlayerInitial || 
            state is PlayerStopped || 
            state is PlayerError) {
          return const SizedBox.shrink();
        }

        // 获取当前歌曲信息
        String songTitle = '';
        String songArtist = '';
        bool isPlaying = false;
        bool isBuffering = false;

        if (state is PlayerPlaying) {
          songTitle = state.song.title;
          songArtist = state.song.artist ?? 'Unknown';
          isPlaying = true; // PlayerPlaying状态表示歌曲正在播放
        } else if (state is PlayerPaused) {
          songTitle = state.song.title;
          songArtist = state.song.artist ?? 'Unknown';
          isPlaying = false; // PlayerPaused状态表示歌曲已暂停
        } else if (state is PlayerLoading) {
          songTitle = 'Loading...';
          songArtist = '';
        } else if (state is PlayerBuffering) {
          // 如果有缓冲状态，也显示播放器栏
          songTitle = state.song.title;
          songArtist = state.song.artist ?? 'Unknown';
          isBuffering = true;
        }

        return Container(
          height: 60.0,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4.0,
                spreadRadius: 1.0,
              ),
            ],
          ),
          child: Row(
            children: [
              // 专辑封面占位符
              Container(
                width: 60.0,
                height: 60.0,
                color: Colors.grey[300],
                child: const Icon(
                  Icons.music_note,
                  size: 30.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 12.0),

              // 歌曲信息
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      songTitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      songArtist,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),

              // 播放控制按钮
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: isBuffering ? Colors.grey : null, // 灰色显示缓冲状态
                ),
                onPressed: () {
                  if (!isBuffering) { // 如果正在缓冲，禁用按钮
                    context.read<PlayerBloc>().add(TogglePlayPauseEvent());
                  }
                },
              ),

              // 如果是桌面端，添加额外的控制按钮
              if (PlatformDetector.isDesktop) ...[
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: () {
                    context.read<PlayerBloc>().add(SkipToPreviousEvent());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: () {
                    context.read<PlayerBloc>().add(SkipToNextEvent());
                  },
                ),
              ],

              const SizedBox(width: 8.0),
            ],
          ),
        );
      },
    );
  }
}