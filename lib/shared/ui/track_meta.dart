import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/source_badge.dart';
import 'package:tune/shared/ui/track_details_button.dart';
import 'package:tune/shared/ui/track_fact_strip.dart';
import 'package:tune/shared/ui/track_position.dart';
import 'package:tune/shared/utils/duration_format.dart';

/// Identity of a track inside a list: position, artwork, metadata, source.
///
/// The favorites and the queue are built on this widget, so a track reads
/// the same way in every stacked list of the shell. The library is a table
/// and writes its own row, but it takes the position and the details action
/// from the same shared widgets.
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
        TrackPosition(index: index, selected: selected, playing: playing),
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
          TrackDetailsButton(
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
