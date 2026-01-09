import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/states/play_mode.dart';
import 'package:tune/ui/theme/app_design_system.dart';

/// 现代化播放器控制组件
/// 提供美观且易用的播放控制界面
class PlayerControls extends ConsumerWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 随机播放按钮
        _buildControlButton(
          icon: Icons.shuffle_rounded,
          iconSize: AppDesignSystem.iconSize24,
          onTap: () {
            // 根据当前模式切换到随机播放
            if (playerState.playMode == PlayMode.shuffle) {
              // playerNotifier.setPlayMode(PlayMode.sequential);
            } else {
              // playerNotifier.setPlayMode(PlayMode.shuffle);
            }
          },
          isActive: playerState.playMode == PlayMode.shuffle,
          theme: theme,
        ),
        
        const SizedBox(width: AppDesignSystem.spacing24),
        
        // 上一曲按钮
        _buildControlButton(
          icon: Icons.skip_previous_rounded,
          iconSize: AppDesignSystem.iconSize32,
          onTap: playerState.currentSong != null ? playerNotifier.previous : null,
          theme: theme,
          isLarge: true,
        ),
        
        const SizedBox(width: AppDesignSystem.spacing32),
        
        // 播放/暂停按钮
        Container(
          width: AppDesignSystem.albumCoverSize80,
          height: AppDesignSystem.albumCoverSize80,
          decoration: BoxDecoration(
            gradient: AppDesignSystem.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppDesignSystem.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: playerState.currentSong != null
                  ? () {
                      if (playerState.isPlaying) {
                        playerNotifier.pause();
                      } else {
                        playerNotifier.resume();
                      }
                    }
                  : null,
              borderRadius: BorderRadius.circular(AppDesignSystem.albumCoverSize80 / 2),
              child: Center(
                child: Icon(
                  playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: AppDesignSystem.iconSize40,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: AppDesignSystem.spacing32),
        
        // 下一曲按钮
        _buildControlButton(
          icon: Icons.skip_next_rounded,
          iconSize: AppDesignSystem.iconSize32,
          onTap: playerState.currentSong != null ? playerNotifier.next : null,
          theme: theme,
          isLarge: true,
        ),
        
        const SizedBox(width: AppDesignSystem.spacing24),
        
        // 循环播放按钮
        _buildControlButton(
          icon: _getRepeatIcon(playerState.playMode),
          iconSize: AppDesignSystem.iconSize24,
          onTap: () => _cyclePlayMode(playerNotifier),
          isActive: playerState.playMode != PlayMode.sequential,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required double iconSize,
    required VoidCallback? onTap,
    required ThemeData theme,
    bool isActive = false,
    bool isLarge = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(isLarge ? AppDesignSystem.radius24 : AppDesignSystem.radius20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isLarge ? AppDesignSystem.radius24 : AppDesignSystem.radius20),
        child: Container(
          width: isLarge ? AppDesignSystem.iconSize56 : AppDesignSystem.iconSize48,
          height: isLarge ? AppDesignSystem.iconSize56 : AppDesignSystem.iconSize48,
          decoration: BoxDecoration(
            color: isActive 
                ? AppDesignSystem.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(isLarge ? AppDesignSystem.radius24 : AppDesignSystem.radius20),
            border: isActive 
                ? Border.all(color: AppDesignSystem.primary, width: 1)
                : null,
          ),
          child: Center(
            child: Icon(
              icon,
              color: isActive 
                  ? AppDesignSystem.primary
                  : (isDark ? AppDesignSystem.neutral300 : AppDesignSystem.neutral700),
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getRepeatIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequential:
        return Icons.repeat_rounded;
      case PlayMode.shuffle:
        return Icons.shuffle_rounded;
      case PlayMode.repeatOne:
        return Icons.repeat_one_rounded;
    }
  }

  void _cyclePlayMode(dynamic playerNotifier) {
    // 这里需要根据实际的PlayMode枚举来实现
    // 假设有 sequential -> shuffle -> repeatOne -> sequential 的循环
    // playerNotifier.cyclePlayMode();
  }
}