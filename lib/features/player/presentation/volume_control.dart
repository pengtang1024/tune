import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/features/player/application/playback_controller.dart';

class VolumeControl extends ConsumerStatefulWidget {
  const VolumeControl({super.key});

  @override
  ConsumerState<VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends ConsumerState<VolumeControl> {
  double _lastNonZero = 1.0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final theme = Theme.of(context);
    final volume = state.volume;

    if (volume > 0) _lastNonZero = volume;

    return Row(
      children: [
        IconButton(
          tooltip: volume > 0 ? '静音' : '恢复音量',
          onPressed: () {
            controller.setVolume(volume > 0 ? 0 : _lastNonZero);
          },
          icon: Icon(
            volume == 0
                ? Icons.volume_off_rounded
                : volume < 0.5
                ? Icons.volume_down_rounded
                : Icons.volume_up_rounded,
            size: CompactTokens.icon18,
          ),
          style: IconButton.styleFrom(
            fixedSize: const Size.square(28),
            minimumSize: const Size.square(28),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: CompactTokens.space6),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.outlineVariant,
              thumbColor: theme.colorScheme.primary,
            ),
            child: SizedBox(
              height: 24,
              child: Slider(
                value: volume.clamp(0.0, 1.0).toDouble(),
                onChanged: controller.setVolume,
              ),
            ),
          ),
        ),
        const SizedBox(width: CompactTokens.space6),
        SizedBox(
          width: 30,
          child: Text(
            '${(volume.clamp(0.0, 1.0) * 100).round()}%',
            textAlign: TextAlign.right,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
