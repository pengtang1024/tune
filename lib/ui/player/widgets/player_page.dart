import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/widgets/player_content.dart';
import 'package:tune/ui/player/widgets/player_controls.dart';
import 'package:tune/ui/player/widgets/player_history.dart';
import 'package:tune/ui/player/widgets/player_options.dart';
import 'package:tune/ui/player/widgets/player_progress.dart';

/// 播放器首页面
class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 错误状态显示
              if (playerState.isError) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            '播放错误',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            playerState.errorMessage,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (playerState.currentSong != null) {
                                playerNotifier.playSong(playerState.currentSong!);
                              }
                            },
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              
              // 专辑封面和歌曲信息
              Expanded(
                child: playerState.isLoading || playerState.isError
                    ? const Center(child: CircularProgressIndicator())
                    : const PlayerContent(),
              ),
              
              // 播放控制
              if (!playerState.isLoading && !playerState.isError) ...[
                const PlayerProgress(),
                const PlayerControls(),
                const PlayerOptions(),
                const PlayerHistory(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}