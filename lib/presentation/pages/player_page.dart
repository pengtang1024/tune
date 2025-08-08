import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/presentation/bloc/player/player_bloc.dart';
import 'package:tune/presentation/bloc/player/player_state.dart';
import 'package:tune/presentation/bloc/player/player_event.dart';

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
    return const Column(
      children: [
        // 专辑封面
        AlbumArt(),
        
        // 歌曲信息
        SongInfo(),
        
        // 进度条
        PlaybackProgress(),
        
        // 控制按钮
        PlayerControls(),
        
        // 音量控制
        VolumeControl(),
      ],
    );
  }
}

class AlbumArt extends StatelessWidget {
  const AlbumArt({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.music_note,
        size: 100,
        color: Colors.grey,
      ),
    );
  }
}

class SongInfo extends StatelessWidget {
  const SongInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        String title = 'Unknown Title';
        String artist = 'Unknown Artist';
        String album = 'Unknown Album';
        
        if (state is PlayerPlaying) {
          title = state.song.title;
          artist = state.song.artist;
          album = state.song.album;
        } else if (state is PlayerPaused) {
          title = state.song.title;
          artist = state.song.artist;
          album = state.song.album;
        }
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                artist,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                album,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PlaybackProgress extends StatelessWidget {
  const PlaybackProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        Duration position = Duration.zero;
        Duration duration = Duration.zero;
        
        if (state is PlayerPlaying) {
          position = state.position;
          duration = state.duration;
        } else if (state is PlayerPaused) {
          position = state.position;
          duration = state.duration;
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Slider(
                value: duration.inMilliseconds == 0 
                    ? 0 
                    : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0).toDouble(),
                onChanged: (value) {
                  final newPosition = Duration(milliseconds: (duration.inMilliseconds * value).toInt());
                  context.read<PlayerBloc>().add(SeekToEvent(newPosition));
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position)),
                  Text(_formatDuration(duration)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        bool isPlaying = state is PlayerPlaying;
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 添加播放模式和播放速度控制
              const PlaybackOptions(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shuffle),
                    onPressed: () {
                      context.read<PlayerBloc>().add(SetPlayModeEvent(PlayMode.shuffle));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 40,
                    onPressed: () {
                      context.read<PlayerBloc>().add(SkipToPreviousEvent());
                    },
                  ),
                  CircleAvatar(
                    radius: 30,
                    child: IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      iconSize: 30,
                      onPressed: () {
                        context.read<PlayerBloc>().add(TogglePlayPauseEvent());
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 40,
                    onPressed: () {
                      context.read<PlayerBloc>().add(SkipToNextEvent());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.repeat),
                    onPressed: () {
                      context.read<PlayerBloc>().add(SetPlayModeEvent(PlayMode.repeatAll));
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class PlaybackOptions extends StatefulWidget {
  const PlaybackOptions({super.key});

  @override
  State<PlaybackOptions> createState() => _PlaybackOptionsState();
}

class _PlaybackOptionsState extends State<PlaybackOptions> {
  double _playbackSpeed = 1.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 播放速度控制
        Row(
          children: [
            const Text('Speed: '),
            DropdownButton<double>(
              value: _playbackSpeed,
              items: const [
                DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                DropdownMenuItem(value: 0.75, child: Text('0.75x')),
                DropdownMenuItem(value: 1.0, child: Text('1.0x')),
                DropdownMenuItem(value: 1.25, child: Text('1.25x')),
                DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                DropdownMenuItem(value: 2.0, child: Text('2.0x')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _playbackSpeed = value;
                    context.read<PlayerBloc>().add(SetPlaybackSpeedEvent(value));
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class VolumeControl extends StatelessWidget {
  const VolumeControl({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        double volume = 0.7;
        
        if (state is PlayerPlaying) {
          volume = state.volume;
        } else if (state is PlayerPaused) {
          volume = state.volume;
        }
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.volume_down),
                  Expanded(
                    child: Slider(
                      value: volume,
                      onChanged: (value) {
                        context.read<PlayerBloc>().add(SetVolumeEvent(value));
                      },
                    ),
                  ),
                  const Icon(Icons.volume_up),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}