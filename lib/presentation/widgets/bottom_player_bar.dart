import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/utils/localization_delegate.dart';
import 'package:tune/presentation/bloc/player/player_bloc.dart';
import 'package:auto_route/auto_route.dart';
import 'package:tune/core/routes/app_router.dart';
import 'package:tune/presentation/bloc/player/player_event.dart';
import 'package:tune/presentation/bloc/player/player_state.dart';

class BottomPlayerBar extends StatelessWidget {
  const BottomPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          String songTitle = localizations.bottomPlayerBarNoSong;
          String artistName = '';

          if (state is PlayerPlaying || state is PlayerPaused) {
            final song = state is PlayerPlaying ? state.song : (state as PlayerPaused).song;
            songTitle = song.title;
            artistName = song.artist;
          }

          return Row(
            children: [
              // 专辑封面占位符
              Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.music_note),
              ),
              const SizedBox(width: 12),
              // 歌曲信息
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      songTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      artistName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 控制按钮
              IconButton(
                icon: (state is PlayerPlaying)
                    ? const Icon(Icons.pause)
                    : const Icon(Icons.play_arrow),
                onPressed: () {
                  if (state is PlayerPlaying || state is PlayerPaused) {
                    context.read<PlayerBloc>().add(TogglePlayPauseEvent());
                  } else {
                    // 如果没有正在播放的歌曲，跳转到主页选择歌曲
                    context.pushRoute(const HomeRoute());
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: () {
                  context.read<PlayerBloc>().add(SkipToNextEvent());
                },
              ),
              const SizedBox(width: 8),
            ],
          );
        },
      ),
    );
  }
}
