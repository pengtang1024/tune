import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/presentation/bloc/player/player_bloc.dart';
import 'package:tune/presentation/bloc/player/player_state.dart';
import 'package:tune/presentation/bloc/player/player_event.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
      ),
      body: const PlayerView(),
    );
  }
}

class PlayerView extends StatelessWidget {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        if (state is PlayerLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PlayerPlaying || state is PlayerPaused) {
          final song = state is PlayerPlaying ? state.song : (state as PlayerPaused).song;
          final isPlaying = state is PlayerPlaying;

          return Column(
            children: [
              // 专辑封面区域
              Container(
                height: 300,
                width: double.infinity,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.music_note,
                  size: 100,
                ),
              ),
              // 歌曲信息
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      song.artist,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: Theme.of(context).textTheme.bodySmall!.color,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song.album ?? 'Unknown Album',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).textTheme.bodySmall!.color,
                          ),
                    ),
                  ],
                ),
              ),
              // 播放控制区域
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: () {
                        context.read<PlayerBloc>().add(SkipToPreviousEvent());
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 48,
                      ),
                      onPressed: () {
                        context.read<PlayerBloc>().add(TogglePlayPauseEvent());
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: () {
                        context.read<PlayerBloc>().add(SkipToNextEvent());
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        } else if (state is PlayerStopped) {
          return const Center(
            child: Text('No song is currently playing'),
          );
        } else {
          return const Center(
            child: Text('Unknown state'),
          );
        }
      },
    );
  }
}
