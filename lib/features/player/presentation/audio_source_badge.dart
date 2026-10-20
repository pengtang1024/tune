import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/player/domain/audio_source_status.dart';

/// Tells where the audio of the current track comes from.
///
/// The badge is shared by the dock and the now playing page so both surfaces
/// describe a remote track the same way.
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

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 2.5 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(dense ? 6 : 8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: dense ? 10 : 12, color: color),
          SizedBox(width: dense ? 4 : 5),
          // The label of a language can be longer than the room the badge
          // gets, so the text gives way instead of overflowing the row.
          Flexible(
            child: Text(
              _label(context, percent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CompactTypography.mono(
                color,
                size: dense ? CompactTypeScale.markDense : CompactTypeScale.mark,
                weight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
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
