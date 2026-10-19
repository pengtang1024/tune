import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/presentation/compact_album_art.dart';
import 'package:tune/features/player/presentation/compact_progress_bar.dart';
import 'package:tune/features/player/presentation/track_info.dart';
import 'package:tune/features/player/presentation/transport_controls.dart';
import 'package:tune/features/player/presentation/volume_control.dart';

class PlayerPane extends ConsumerWidget {
  const PlayerPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);

    return ColoredBox(
      color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.45),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 500;
          final padding = compact
              ? CompactTokens.space12
              : CompactTokens.space16;
          final availableWidth = constraints.maxWidth - padding * 2;
          final reservedHeight = compact ? 230.0 : 250.0;
          final artSize = (constraints.maxHeight - reservedHeight)
              .clamp(120.0, 240.0)
              .toDouble();
          final size = artSize < availableWidth ? artSize : availableWidth;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CompactAlbumArt(
                  path: state.currentSong?.albumArtPath,
                  imageUrl: state.currentSong?.artworkUrl,
                  size: size,
                ),
                const SizedBox(height: 4),
                TrackInfo(
                  song: state.currentSong,
                  errorMessage: state.errorMessage,
                ),
                const SizedBox(height: 2),
                CompactProgressBar(
                  position: state.position,
                  duration: state.duration,
                  enabled: state.hasTrack,
                  onSeek: controller.seekTo,
                ),
                const SizedBox(height: 4),
                const TransportControls(),
                const SizedBox(height: 2),
                const VolumeControl(),
              ],
            ),
          );
        },
      ),
    );
  }
}
