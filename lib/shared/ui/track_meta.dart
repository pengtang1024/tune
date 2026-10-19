import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/source_chip.dart';
import 'package:tune/shared/utils/duration_format.dart';

/// Identity of a track inside a list: position, artwork, metadata, source.
///
/// The library card and the queue row are built on this widget, so a track
/// always reads the same way wherever it is listed.
class TrackMeta extends StatelessWidget {
  final Song song;
  final int index;
  final String? sourceName;
  final bool selected;
  final bool playing;
  final double artworkSize;

  const TrackMeta({
    super.key,
    required this.song,
    required this.index,
    this.sourceName,
    this.selected = false,
    this.playing = false,
    this.artworkSize = 40,
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
                  fontSize: 13,
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
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (sourceName != null) ...[
          const SizedBox(width: CompactTokens.space8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: SourceChip(label: sourceName!, dense: true),
          ),
        ],
        const SizedBox(width: CompactTokens.space8),
        Text(
          formatDuration(Duration(milliseconds: song.durationInMillis)),
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
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
      width: 22,
      child: Center(
        child: selected
            ? Icon(
                playing ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
                size: CompactTokens.icon16,
                color: theme.colorScheme.primary,
              )
            : Text(
                '${index + 1}',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.75,
                  ),
                ),
              ),
      ),
    );
  }
}
