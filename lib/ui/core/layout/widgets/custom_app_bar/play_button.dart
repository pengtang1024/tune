import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/widgets/animation/playing_state_animation.dart';

/// 播放按钮组件
/// 负责控制音乐播放/暂停，并显示播放状态
class PlayButton extends ConsumerWidget {
  const PlayButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final appBarState = ref.watch(appBarStateNotifierProvider);
    final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);

    // 根据播放状态和悬停状态确定图标
    Widget getPlayIcon() {
      if (appBarState.isPlayButtonHovered) {
        // 悬停状态
        if (playerState.isPlaying) {
          return const Icon(Icons.pause); // 播放状态悬停显示暂停图标
        } else {
          return const Icon(Icons.play_arrow); // 暂停/停止状态悬停显示播放图标
        }
      } else {
        // 常态
        if (playerState.isPlaying) {
          // 播放状态显示播放中动画
          return const PlayingStateAnimation(isPlaying: true);
        } else {
          return const Icon(Icons.play_arrow); // 暂停/停止状态显示播放图标
        }
      }
    }

    return MouseRegion(
      onEnter: (_) {
        // 鼠标悬停时更新状态
        appBarNotifier.setPlayButtonHover(true);
      },
      onExit: (_) {
        // 鼠标离开时更新状态
        appBarNotifier.setPlayButtonHover(false);
      },
      child: GestureDetector(
        onLongPress: () {
          // 长按停止播放
          playerNotifier.stop();
        },
        child: IconButton(
          icon: getPlayIcon(),
          tooltip: playerState.isPlaying ? '暂停' : '播放',
          onPressed: () {
            // 点击切换播放状态
            if (playerState.isPlaying) {
              playerNotifier.pause();
            } else {
              playerNotifier.play();
            }
          },
        ),
      ),
    );
  }
}
