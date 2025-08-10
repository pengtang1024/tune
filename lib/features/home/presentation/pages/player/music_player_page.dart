import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:auto_route/auto_route.dart';
import 'package:tune/core/utils/platform_detector.dart';
import 'package:tune/features/home/presentation/bloc/player/player_bloc.dart';
import 'package:tune/features/home/presentation/bloc/player/player_state.dart';
import 'package:tune/features/home/presentation/bloc/player/player_event.dart';
import 'package:tune/l10n/app_localizations.dart';

class SongArtist extends StatelessWidget {
  final String artist;
  final TextStyle? style;

  const SongArtist({super.key, required this.artist, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      artist,
      style: style ?? Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
    );
  }
}

class HeadlineTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;

  const HeadlineTitle({super.key, required this.title, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: style ?? Theme.of(context).textTheme.headlineSmall,
    );
  }
}

@RoutePage()
class MusicPlayerPage extends StatelessWidget {
  const MusicPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    // 检查是否应该使用移动端布局（基于屏幕尺寸）
    final bool useMobileLayout = MediaQuery.of(context).size.width < 600;

    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        if (state is PlayerInitial || state is PlayerLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is PlayerError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: 重新加载
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is PlayerStopped) {
          return Scaffold(
            body: Center(
              child: Text(localizations.no_song_playing),
            ),
          );
        }

        Song? currentSong;
        Duration progress = Duration.zero;
        bool isPlaying = false;

        if (state is PlayerPlaying) {
          currentSong = state.song;
          progress = state.position;
          isPlaying = true;
        } else if (state is PlayerPaused) {
          currentSong = state.song;
          progress = state.position;
          isPlaying = false;
        } else if (state is PlayerBuffering) {
          currentSong = state.song;
          progress = state.position;
        }

        if (currentSong == null) {
          return const Scaffold(
            body: Center(
              child: Text('No song playing'),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 顶部控制栏
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (useMobileLayout)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      else
                        const Spacer(),
                      Text(
                        localizations.bottom_player_bar_now_playing,
                        style: (Theme.of(context).textTheme.titleLarge ?? const TextStyle())
                            .copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 专辑封面
                  Center(
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.music_note,
                        size: 120,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 歌曲信息
                  Center(
                    child: Column(
                      children: [
                        HeadlineTitle(title: currentSong.title),
                        const SizedBox(height: 8),
                        SongArtist(artist: currentSong.artist),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 进度条
                  Column(
                    children: [
                      Slider(
                        value: progress.inMilliseconds.toDouble(),
                        min: 0.0,
                        max: currentSong.duration.toDouble(),
                        onChanged: (value) {
                          // TODO: 更新进度
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(progress)),
                            Text(_formatDuration(Duration(milliseconds: currentSong.duration))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 播放控制按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 48,
                        onPressed: () {
                          context.read<PlayerBloc>().add(SkipToPreviousEvent());
                        },
                      ),
                      FloatingActionButton(
                        onPressed: () {
                          context.read<PlayerBloc>().add(TogglePlayPauseEvent());
                        },
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 48,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        iconSize: 48,
                        onPressed: () {
                          context.read<PlayerBloc>().add(SkipToNextEvent());
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 音量控制和其他按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () {
                          // TODO: 显示音量控制
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.shuffle),
                        onPressed: () {
                          // TODO: 随机播放
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.repeat),
                        onPressed: () {
                          // TODO: 循环播放
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.playlist_play),
                        onPressed: () {
                          // TODO: 显示播放列表
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 格式化时间显示
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}