import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/player/domain/audio_source_status.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// Tells where the audio of the current track comes from.
///
/// The badge is shared by the dock and the now playing page so both surfaces
/// describe a remote track the same way.
///
/// The badge is an icon, not a word: the dock is the tightest place in the
/// app, and a badge that grows with its words would push the title around.
/// The mouse says what the badge means, and the colour says how it goes.
class AudioSourceBadge extends StatelessWidget {
  final AudioSourceStatus status;
  final double progress;
  final bool dense;

  const AudioSourceBadge({
    super.key,
    required this.status,
    this.progress = 0,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color(theme);
    final percent = (progress.clamp(0.0, 1.0) * 100).round();

    return TuneTooltip(
      message: _label(context, percent),
      child: Container(
        width: dense ? 18 : 22,
        height: dense ? 18 : 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(dense ? 5 : 6),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Icon(_icon, size: dense ? 11 : 13, color: color),
      ),
    );
  }

  String _label(BuildContext context, int percent) {
    return switch (status) {
      AudioSourceStatus.local => context.loc.audioSourceLocal,
      AudioSourceStatus.caching => context.loc.audioSourceCaching(percent),
      AudioSourceStatus.cached => context.loc.audioSourceCached,
      AudioSourceStatus.streaming => context.loc.audioSourceStreaming,
      AudioSourceStatus.failed => context.loc.audioSourceFailed,
    };
  }

  IconData get _icon {
    return switch (status) {
      AudioSourceStatus.local => Icons.sd_storage_rounded,
      AudioSourceStatus.caching => Icons.downloading_rounded,
      AudioSourceStatus.cached => Icons.offline_pin_rounded,
      AudioSourceStatus.streaming => Icons.podcasts_rounded,
      AudioSourceStatus.failed => Icons.error_outline_rounded,
    };
  }

  Color _color(ThemeData theme) {
    return switch (status) {
      AudioSourceStatus.local => theme.colorScheme.onSurfaceVariant,
      AudioSourceStatus.caching => theme.colorScheme.primary,
      AudioSourceStatus.cached => theme.colorScheme.secondary,
      AudioSourceStatus.streaming => theme.colorScheme.tertiary,
      AudioSourceStatus.failed => theme.colorScheme.error,
    };
  }
}
