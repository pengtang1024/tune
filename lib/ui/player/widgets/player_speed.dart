import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_interactions.dart';

class PlayerSpeed extends ConsumerWidget {
  const PlayerSpeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.speed_rounded,
          size: AppDesignSystem.iconSize20,
          color: AppDesignSystem.primary,
        ),
        const SizedBox(width: AppDesignSystem.spacing8),
        Flexible(
          child: Wrap(
            spacing: AppDesignSystem.spacing4,
            runSpacing: AppDesignSystem.spacing4,
            children: speeds.map((speed) {
              final isActive = playerState.speed == speed;
              return AppInteractions.pressableScale(
                scaleValue: 0.93,
                onTap: () => playerNotifier.setSpeed(speed),
                child: AnimatedContainer(
                  duration: AppDesignSystem.duration200,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacing10,
                    vertical: AppDesignSystem.spacing6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppDesignSystem.primary
                        : AppDesignSystem.primary.withValues(alpha: 0.08),
                    borderRadius: AppDesignSystem.borderRadius8,
                  ),
                  child: Text(
                    '${speed}x',
                    style: AppDesignSystem.textTheme.labelSmall?.copyWith(
                      color: isActive ? Colors.white : AppDesignSystem.primary,
                      fontWeight: isActive
                          ? AppDesignSystem.fontWeightBold
                          : AppDesignSystem.fontWeightMedium,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
