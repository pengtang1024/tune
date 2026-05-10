import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_interactions.dart';

class PlayerVolume extends ConsumerWidget {
  const PlayerVolume({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppInteractions.pressableScale(
          scaleValue: 0.9,
          onTap: () => playerNotifier.setVolume(0),
          child: Icon(
            Icons.volume_mute_rounded,
            size: AppDesignSystem.iconSize20,
            color: AppDesignSystem.neutral400,
          ),
        ),
        SizedBox(
          width: 100,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: AppDesignSystem.primary,
              inactiveTrackColor: AppDesignSystem.neutral300,
              thumbColor: AppDesignSystem.primary,
            ),
            child: Slider(
              value: playerState.volume,
              onChanged: playerNotifier.setVolume,
            ),
          ),
        ),
        AppInteractions.pressableScale(
          scaleValue: 0.9,
          onTap: () => playerNotifier.setVolume(1),
          child: Icon(
            Icons.volume_up_rounded,
            size: AppDesignSystem.iconSize20,
            color: AppDesignSystem.neutral400,
          ),
        ),
      ],
    );
  }
}
