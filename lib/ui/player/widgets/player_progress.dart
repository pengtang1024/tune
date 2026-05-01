import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';

/// 现代化播放进度条组件
/// 提供美观且易用的进度控制界面
class PlayerProgress extends ConsumerWidget {
  const PlayerProgress({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing24),
      child: Column(
        children: [
          // 进度条
          Theme(
            data: Theme.of(context).copyWith(
              sliderTheme: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: AppDesignSystem.primary,
                inactiveTrackColor: isDark 
                    ? AppDesignSystem.neutral700 
                    : AppDesignSystem.neutral300,
                thumbColor: AppDesignSystem.primary,
                overlayColor: AppDesignSystem.primary.withValues(alpha: 0.2),
                valueIndicatorColor: AppDesignSystem.primary,
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: AppDesignSystem.fontSize12,
                ),
              ),
            ),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              ),
              child: Slider(
                min: 0.0,
                max: 1.0,
                value: playerState.duration.inMilliseconds == 0
                    ? 0
                    : (playerState.position.inMilliseconds / playerState.duration.inMilliseconds)
                        .clamp(0.0, 1.0)
                        .toDouble(),
                onChanged: (value) {
                  final newPosition = Duration(
                    milliseconds: (playerState.duration.inMilliseconds * value).toInt(),
                  );
                  playerNotifier.seekTo(newPosition);
                },
              ),
            ),
          ),
          
          const SizedBox(height: AppDesignSystem.spacing8),
          
          // 时间显示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(playerState.position),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark 
                        ? AppDesignSystem.neutral400 
                        : AppDesignSystem.neutral600,
                    fontSize: AppDesignSystem.fontSize12,
                    fontWeight: AppDesignSystem.fontWeightMedium,
                  ),
                ),
                Text(
                  _formatDuration(playerState.duration),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark 
                        ? AppDesignSystem.neutral400 
                        : AppDesignSystem.neutral600,
                    fontSize: AppDesignSystem.fontSize12,
                    fontWeight: AppDesignSystem.fontWeightMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}