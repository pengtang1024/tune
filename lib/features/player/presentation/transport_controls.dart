import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_state.dart';

class TransportControls extends ConsumerWidget {
  const TransportControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ModeButton(state: state, onPressed: controller.cyclePlayMode),
        const SizedBox(width: CompactTokens.space12),
        _StepButton(
          icon: Icons.skip_previous_rounded,
          tooltip: context.loc.previous,
          onPressed: state.hasTrack ? controller.previous : null,
        ),
        const SizedBox(width: CompactTokens.space16),
        _PlayPauseButton(
          state: state,
          onPressed: state.hasTrack && !state.isLoading
              ? controller.togglePlayPause
              : null,
        ),
        const SizedBox(width: CompactTokens.space16),
        _StepButton(
          icon: Icons.skip_next_rounded,
          tooltip: context.loc.next,
          onPressed: state.hasTrack ? controller.next : null,
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final PlaybackState state;
  final VoidCallback onPressed;

  const _ModeButton({required this.state, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = state.playMode != PlayMode.sequential;

    final (icon, label) = switch (state.playMode) {
      PlayMode.sequential => (Icons.repeat_rounded, context.loc.repeat_all),
      PlayMode.repeatOne => (Icons.repeat_one_rounded, context.loc.repeat_one),
      PlayMode.shuffle => (Icons.shuffle_rounded, context.loc.shuffle),
    };

    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon, size: CompactTokens.icon18),
      color: active
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurfaceVariant,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(CompactTokens.controlSmall),
        minimumSize: const Size.square(CompactTokens.controlSmall),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: CompactTokens.icon24),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(CompactTokens.controlMedium),
        minimumSize: const Size.square(CompactTokens.controlMedium),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final PlaybackState state;
  final VoidCallback? onPressed;

  const _PlayPauseButton({required this.state, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: CompactTokens.controlLarge,
      height: CompactTokens.controlLarge,
      child: IconButton.filled(
        tooltip: state.isPlaying ? context.loc.pause : context.loc.play,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          disabledBackgroundColor: theme.colorScheme.primary.withValues(
            alpha: 0.35,
          ),
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: state.isLoading
            ? SizedBox(
                width: CompactTokens.icon20,
                height: CompactTokens.icon20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : Icon(
                state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: CompactTokens.icon28,
              ),
      ),
    );
  }
}
