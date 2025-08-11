import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/domain/entities/song.dart';
// 更新导入路径到 audio 模块
import 'package:tune/features/audio/presentation/bloc/player/player_bloc.dart';
import 'package:tune/features/audio/presentation/bloc/player/player_event.dart';
import 'package:tune/features/audio/presentation/bloc/player/player_state.dart';
import 'package:tune/l10n/app_localizations.dart';

class SongArtist extends StatelessWidget {
  final String artist;
  final TextStyle? style;

  const SongArtist({super.key, required this.artist, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(artist, style: style ?? Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color));
  }
}

class HeadlineTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;

  const HeadlineTitle({super.key, required this.title, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: style ?? Theme.of(context).textTheme.headlineSmall);
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

    return BlocConsumer<PlayerBloc, PlayerState>(
      listener: (context, state) {
        // 可以在这里处理状态变化的副作用
        if (state is PlayerError) {
          // 处理错误状态，例如显示错误消息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        Song? currentSong;
        Duration? currentPosition;
        Duration? totalDuration;
        bool isPlaying = false;

        if (state is PlayerPlaying) {
          currentSong = state.song;
          currentPosition = state.position;
          totalDuration = state.duration;
          isPlaying = true;
        } else if (state is PlayerPaused) {
          currentSong = state.song;
          currentPosition = state.position;
          totalDuration = state.duration;
          isPlaying = false;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.player_title),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: currentSong == null ? _buildEmptyPlayer(context, localizations) : _buildPlayerContent(context, localizations, currentSong, currentPosition, totalDuration, isPlaying, useMobileLayout),
        );
      },
    );
  }

  Widget _buildEmptyPlayer(BuildContext context, AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            localizations.no_song_playing, // 修复：使用正确的本地化字符串
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerContent(BuildContext context, AppLocalizations localizations, Song song, Duration? currentPosition, Duration? totalDuration, bool isPlaying, bool useMobileLayout) {
    return Column(
      children: [
        // 专辑封面区域
        _buildAlbumArt(song, useMobileLayout),

        // 歌曲信息
        _buildSongInfo(context, song),

        // 进度条
        _buildProgress(context, currentPosition ?? Duration.zero, totalDuration ?? Duration.zero),

        // 控制按钮
        _buildControlButtons(context, isPlaying),

        const Spacer(),

        // 音量控制
        _buildVolumeControl(context),
      ],
    );
  }

  Widget _buildAlbumArt(Song song, bool useMobileLayout) {
    final imageSize = useMobileLayout ? 300.0 : 400.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Icon(Icons.music_note, size: imageSize * 0.5, color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildSongInfo(BuildContext context, Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          HeadlineTitle(title: song.title),
          const SizedBox(height: 8),
          SongArtist(artist: song.artist),
          ...[const SizedBox(height: 4), Text(song.album, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color))],
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context, Duration currentPosition, Duration totalDuration) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Slider(
            value: currentPosition.inMilliseconds.toDouble(),
            min: 0,
            max: totalDuration.inMilliseconds.toDouble(),
            onChanged: (value) {
              context.read<PlayerBloc>().add(SeekToEvent(Duration(milliseconds: value.toInt())));
            },
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_formatDuration(currentPosition)), Text(_formatDuration(totalDuration))]),
        ],
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context, bool isPlaying) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 36,
            onPressed: () {
              context.read<PlayerBloc>().add(SkipToPreviousEvent());
            },
          ),
          FloatingActionButton(
            onPressed: () {
              context.read<PlayerBloc>().add(TogglePlayPauseEvent());
            },
            child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 36),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 36,
            onPressed: () {
              context.read<PlayerBloc>().add(SkipToNextEvent());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeControl(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.volume_down),
          Expanded(
            child: Slider(
              value: 0.5, // 简化实现，实际应该从 bloc 状态获取
              onChanged: (value) {
                context.read<PlayerBloc>().add(SetVolumeEvent(value));
              },
            ),
          ),
          const Icon(Icons.volume_up),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
