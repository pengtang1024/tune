import 'package:flutter/material.dart';

/// 播放控制组件
class PlayerControls extends StatelessWidget {
  /// 是否正在播放
  final bool isPlaying;

  /// 播放/暂停回调
  final VoidCallback? onPlayPause;

  /// 上一首回调
  final VoidCallback? onPrevious;

  /// 下一首回调
  final VoidCallback? onNext;

  /// 构造函数
  const PlayerControls({
    super.key,
    required this.isPlaying,
    this.onPlayPause,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: 48.0,
          onPressed: onPrevious,
        ),
        const SizedBox(width: 16.0),
        FloatingActionButton(
          onPressed: onPlayPause,
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            size: 48.0,
          ),
        ),
        const SizedBox(width: 16.0),
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: 48.0,
          onPressed: onNext,
        ),
      ],
    );
  }
}