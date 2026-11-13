import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/content_kind_mark.dart';
import 'package:tune/shared/ui/content_row.dart';
import 'package:tune/shared/ui/live_badge.dart';
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

  /// Draws the title when the caller wants it in another language.
  ///
  /// The shared row stays free of the localisation provider; the page that
  /// has it hands in a widget of its own and the row only decides where the
  /// title goes and which style it wears.
  final Widget Function(String text, TextStyle? style)? titleBuilder;

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
    this.titleBuilder,
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
              _title(context, theme),
              const SizedBox(height: 2),
              if (dense)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _denseByline(context, song),
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
                    if (song.isLiveStream)
                      const LiveBadge()
                    else ...[
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
                  rowSubtitleOf(context, song),
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

  Widget _title(BuildContext context, ThemeData theme) {
    final text = song.title.isEmpty
        ? context.loc.trackUnknownTitle
        : song.title;
    final style = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      color: selected ? theme.colorScheme.primary : null,
    );
    final builder = titleBuilder;
    final Widget title = builder != null
        ? builder(text, style)
        : Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          );
    // The dense row keeps no fact strip, so it wears the kind itself. The
    // full row leaves the mark to the strip to say it only once.
    if (!dense) return title;
    return Row(
      children: [
        Flexible(child: title),
        ContentKindMark(song: song),
      ],
    );
  }
}

/// The short line of a dense row.
///
/// A song has room for its artist only. Speech starts with the show and a
/// station writes what is airing, because neither has a usable artist.
String _denseByline(BuildContext context, Song song) {
  if (rowShapeOf(song) == RowShape.track) {
    return song.artist.trim().isEmpty
        ? context.loc.playerUnknownArtist
        : song.artist;
  }
  return rowSubtitleOf(context, song);
}
