import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/source_badge.dart';
import 'package:tune/shared/ui/track_detail_sheet.dart';
import 'package:tune/shared/ui/track_fact_strip.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';
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

  /// Whether the track is one of the favorites.
  ///
  /// The details panel marks the track with a heart, so the row has to say
  /// whether the track is liked. The row itself keeps no copy of the answer.
  final bool isFavorite;

  /// What the heart in the details panel does.
  final VoidCallback? onToggleFavorite;

  /// Whether the row sits in a panel rather than a full page.
  ///
  /// The dense form keeps the title on one line and moves the artist, the
  /// source and the duration to the next. It leaves the fact strip and the
  /// details action to the pages that have room for them.
  final bool dense;

  const TrackMeta({
    super.key,
    required this.song,
    required this.index,
    this.source,
    this.selected = false,
    this.playing = false,
    this.artworkSize = CompactTokens.artworkRow,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.dense = false,
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
              if (dense)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        song.artist.isEmpty
                            ? context.loc.playerUnknownArtist
                            : song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (source != null) ...[
                      const SizedBox(width: CompactTokens.space4),
                      SourceBadge(label: source!, dense: true),
                    ],
                    if (!song.isLiveStream) ...[
                      const SizedBox(width: CompactTokens.space6),
                      Text(
                        formatDuration(
                          Duration(milliseconds: song.durationInMillis),
                        ),
                        style: CompactTypography.mono(
                          theme.colorScheme.onSurfaceVariant,
                          size: CompactTypeScale.mark,
                        ),
                      ),
                    ],
                  ],
                )
              else
                Text(
                  _byline(context, song),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (!dense) ...[
          const SizedBox(width: CompactTokens.space8),
          TrackFactStrip(song: song),
          const SizedBox(width: CompactTokens.space8),
          if (source != null) ...[
            SourceBadge(label: source!, dense: true),
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
          _DetailsButton(
            song: song,
            source: source,
            isFavorite: isFavorite,
            onToggleFavorite: onToggleFavorite,
          ),
        ],
      ],
    );
  }
}

/// The line under the title of a row: who made the track, and the album it
/// belongs to.
///
/// The album was only written down in the details panel, which left a list
/// of long names without the other half of what tells two tracks apart. The
/// line keeps the artist first because that is what a reader looks for, and
/// the album follows the same secondary voice.
String _byline(BuildContext context, Song song) {
  final artist = song.artist.trim().isEmpty
      ? context.loc.playerUnknownArtist
      : song.artist;
  final album = song.album.trim();
  if (album.isEmpty) return artist;
  return '$artist · $album';
}

/// The action that opens everything that is known about a track.
class _DetailsButton extends StatelessWidget {
  final Song song;
  final SourceLabel? source;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const _DetailsButton({
    required this.song,
    this.source,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TuneTooltip(
      message: context.loc.trackDetailsTooltip,
      child: IconButton(
        onPressed: () => showTrackDetailSheet(
          context,
          song,
          source: source,
          isFavorite: isFavorite,
          onToggleFavorite: onToggleFavorite,
        ),
        icon: const Icon(
          Icons.info_outline_rounded,
          size: CompactTokens.icon16,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
        style: IconButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
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
