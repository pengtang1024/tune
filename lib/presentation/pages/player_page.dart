import 'package:flutter/material.dart';

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
import 'package:flutter/material.dart';

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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/presentation/bloc/player/player_bloc.dart';
import 'package:tune/presentation/bloc/player/player_state.dart';
import 'package:tune/presentation/bloc/player/player_event.dart';
import 'package:auto_route/auto_route.dart';
import 'package:tune/core/utils/platform_detector.dart';
import 'package:tune/presentation/widgets/section_title.dart';
import 'package:tune/presentation/widgets/headline_title.dart';
import 'package:tune/presentation/widgets/song_artist.dart';

@RoutePage()
class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    // 检查是否应该使用移动端布局（基于屏幕尺寸）
    final useMobileLayout = PlatformDetector.shouldUseMobileLayout(context);

    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        if (state is PlayerPlaying || state is PlayerPaused) {
          final song = state is PlayerPlaying ? state.song : (state as PlayerPaused).song;
          final isPlaying = state is PlayerPlaying;
          final position = state is PlayerPlaying ? state.position : (state as PlayerPaused).position;
          final duration = state is PlayerPlaying ? state.duration : (state as PlayerPaused).duration;

          if (useMobileLayout) {
            // 移动端布局
            return _MobilePlayerLayout(
              song: song,
              isPlaying: isPlaying,
              position: position,
              duration: duration,
              localizations: localizations,
            );
          } else {
            // 桌面端和Web端布局（大屏幕）
            return _DesktopPlayerLayout(
              song: song,
              isPlaying: isPlaying,
              position: position,
              duration: duration,
              localizations: localizations,
            );
          }
        } else {
          return const Scaffold(
            body: Center(
              child: Text('No song selected'),
            ),
          );
        }
      },
    );
  }
}

class _MobilePlayerLayout extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final AppLocalizations localizations;

  const _MobilePlayerLayout({
    required this.song,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SectionTitle(title: localizations.bottom_player_bar_now_playing),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 专辑封面
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.center,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          // 歌曲信息
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeadlineTitle(
                    title: song.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SongArtist(artist: song.artist),
                  const SizedBox(height: 8),
                  Text(
                    song.album ?? 'Unknown Album',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // 进度条
                  Slider(
                    value: position.inMilliseconds.toDouble(),
                    min: 0,
                    max: duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      context.read<PlayerBloc>().add(
                            SeekToEvent(Duration(milliseconds: value.toInt())),
                          );
                    },
                  ),
                  // 时间显示
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position)),
                      Text(_formatDuration(duration)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 控制按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 40,
                        onPressed: () {
                          context.read<PlayerBloc>().add(SkipToPreviousEvent());
                        },
                      ),
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        iconSize: 50,
                        onPressed: () {
                          context.read<PlayerBloc>().add(TogglePlayPauseEvent());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        iconSize: 40,
                        onPressed: () {
                          context.read<PlayerBloc>().add(SkipToNextEvent());
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopPlayerLayout extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final AppLocalizations localizations;

  const _DesktopPlayerLayout({
    required this.song,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧专辑封面区域
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(32.0),
              alignment: Alignment.center,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    size: 150,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          // 右侧歌曲信息和控制区域
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和关闭按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SectionTitle(
                        title: localizations.bottom_player_bar_now_playing,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // 歌曲信息
                  SectionTitle(
                    title: song.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.artist,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.album ?? 'Unknown Album',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                  const SizedBox(height: 32),
                  // 进度条
                  Slider(
                    value: position.inMilliseconds.toDouble(),
                    min: 0,
                    max: duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      context.read<PlayerBloc>().add(
                            SeekToEvent(Duration(milliseconds: value.toInt())),
                          );
                    },
                  ),
                  // 时间显示
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position)),
                      Text(_formatDuration(duration)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // 控制按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 50,
                        onPressed: () {
                          context.read<PlayerBloc>().add(SkipToPreviousEvent());
                        },
                      ),
                      const SizedBox(width: 32),
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        iconSize: 70,
                        onPressed: () {
                          context.read<PlayerBloc>().add(TogglePlayPauseEvent());
                        },
                      ),
                      const SizedBox(width: 32),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        iconSize: 50,
                        onPressed: () {
                          context.read<PlayerBloc>().add(SkipToNextEvent());
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60);
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}