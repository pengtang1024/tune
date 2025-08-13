import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/app/router/app_router.dart';
import 'package:tune/domain/entities/song.dart';

// 更新导入路径到 audio 模块
import 'package:tune/features/audio/presentation/bloc/player/player_bloc.dart';
import 'package:tune/features/audio/presentation/bloc/player/player_event.dart';
import 'package:tune/features/audio/presentation/bloc/player/player_state.dart';
import 'package:tune/l10n/app_localizations.dart';

class BottomPlayerBar extends StatelessWidget {
  const BottomPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, -2))],
          ),
          child: state is PlayerPlaying || state is PlayerPaused ? _PlayerControls(song: (state as dynamic).song) : _EmptyPlayerBar(localizations: localizations),
        );
      },
    );
  }
}

class _PlayerControls extends StatelessWidget {
  final Song song;

  const _PlayerControls({required this.song});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 专辑封面占位符
        Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.music_note)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                song.artist,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // 播放控制按钮
        IconButton(
          icon: const Icon(Icons.play_arrow),
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
        IconButton(
          icon: const Icon(Icons.queue_music),
          onPressed: () {
            context.router.push(const MusicPlayerRoute());
          },
        ),
      ],
    );
  }
}

class _EmptyPlayerBar extends StatelessWidget {
  final AppLocalizations localizations;

  const _EmptyPlayerBar({required this.localizations});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        const Icon(Icons.music_note),
        const SizedBox(width: 12),
        Text(
          localizations.no_things_players,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () {
            // TODO: 实现播放逻辑
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
