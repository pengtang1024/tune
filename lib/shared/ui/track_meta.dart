import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/source_chip.dart';
import 'package:tune/shared/ui/track_detail_sheet.dart';
import 'package:tune/shared/ui/track_fact_strip.dart';
import 'package:tune/shared/utils/duration_format.dart';

/// Identity of a track inside a list: position, artwork, metadata, source.
///
/// The library card and the queue row are built on this widget, so a track
/// always reads the same way wherever it is listed.
class TrackMeta extends StatelessWidget {
  final Song song;
  final int index;
  final SourceLabel? source;
  final bool selected;
  final bool playing;
  final double artworkSize;

  const TrackMeta({
    super.key,
    required this.song,
    required this.index,
    this.source,
    this.selected = false,
    this.playing = false,
    this.artworkSize = CompactTokens.artworkRow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _Position(index: index, selected: selected, playing: playing),
        const SizedBox(width: CompactTokens.space8),
        ArtworkThumb(
          path: song.albumArtPath,
          imageUrl: song.artworkUrl,
          size: artworkSize,
          radius: artworkSize * 0.22,
        ),
        const SizedBox(width: CompactTokens.space12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title.isEmpty ? context.loc.trackUnknownTitle : song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? theme.colorScheme.primary : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                song.artist.isEmpty
                    ? context.loc.playerUnknownArtist
                    : song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: CompactTokens.space8),
        TrackFactStrip(song: song),
        const SizedBox(width: CompactTokens.space8),
        if (source != null) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 168),
            child: SourceChip(label: source!, dense: true),
          ),
          const SizedBox(width: CompactTokens.space8),
        ],
        if (!song.isLiveStream)
          Text(
            formatDuration(Duration(milliseconds: song.durationInMillis)),
            style: CompactTypography.mono(
              theme.colorScheme.onSurfaceVariant,
              size: CompactTypeScale.mark,
            ),
          ),
        const SizedBox(width: CompactTokens.space4),
        _DetailsButton(song: song, sourceName: source?.name),
      ],
    );
  }
}

/// The action that opens everything that is known about a track.
class _DetailsButton extends StatelessWidget {
  final Song song;
  final String? sourceName;

  const _DetailsButton({required this.song, this.sourceName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      tooltip: context.loc.trackDetailsTooltip,
      onPressed: () =>
          showTrackDetailSheet(context, song, sourceName: sourceName),
      icon: const Icon(Icons.info_outline_rounded, size: CompactTokens.icon16),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      style: IconButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Position of a track in its list.
///
/// The current track replaces its number with the playback indicator so the
/// list always shows where the music is.
class _Position extends StatelessWidget {
  final int index;
  final bool selected;
  final bool playing;

  const _Position({
    required this.index,
    required this.selected,
    required this.playing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: CompactTokens.positionColumnWidth,
      child: Center(
        child: selected
            ? Icon(
                playing ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
                size: CompactTokens.icon16,
                color: theme.colorScheme.primary,
              )
            : Text(
                '${index + 1}',
                style: CompactTypography.mono(
                  theme.colorScheme.onSurfaceVariant,
                  size: CompactTypeScale.mark,
                ),
              ),
      ),
    );
  }
}
