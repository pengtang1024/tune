import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/domain/audio_source_status.dart';
import 'package:tune/features/player/presentation/audio_source_badge.dart';
import 'package:tune/shared/ui/meta_chip.dart';
import 'package:tune/shared/ui/source_badge.dart';
import 'package:tune/shared/ui/track_detail_sheet.dart';
import 'package:tune/shared/ui/track_facts.dart';

/// The words of the track that is playing.
///
/// The block names the source of the sound, the track, the artist and the
/// facts the source published, and it scrolls when the room is too short
/// for all of it.
///
/// The scroll is the point of the block. The desktop has a text scale of
/// its own, and a user who raises it gets words that are a third taller
/// than the window was built for. The page keeps its progress bar and its
/// buttons in sight and lets the words give way, instead of running them
/// over the edge of the window.
class NowPlayingTrackInfo extends StatelessWidget {
  const NowPlayingTrackInfo({
    super.key,
    required this.song,
    required this.source,
    required this.status,
    required this.progress,
  });

  final Song song;
  final SourceLabel source;
  final AudioSourceStatus status;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SourceBadge(
                label: source,
                dense: false,
                onTap: () =>
                    showTrackDetailSheet(context, song, source: source),
              ),
              const SizedBox(width: CompactTokens.space8),
              // The badge tells where the sound comes from, so it belongs
              // next to the name of the source instead of floating at the
              // far end of the seek bar.
              AudioSourceBadge(status: status, progress: progress),
            ],
          ),
          const SizedBox(height: CompactTokens.space16),
          _Title(song: song),
          const SizedBox(height: CompactTokens.space8),
          _Artist(song: song),
          const SizedBox(height: CompactTokens.space14),
          _TrackDetails(song: song, source: source),
        ],
      ),
    );
  }
}

/// The track title.
class _Title extends StatelessWidget {
  const _Title({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      song.title.isEmpty ? context.loc.nowPlayingUnnamedTrack : song.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: CompactTypography.asDisplay(
        theme.textTheme.displayMedium,
        size: CompactTypeScale.displayLarge,
        height: 1.06,
      ),
    );
  }
}

/// The artist line with the album and the year.
class _Artist extends StatelessWidget {
  const _Artist({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artist = song.artist.isEmpty
        ? context.loc.playerUnknownArtist
        : song.artist;
    final details = <String>[
      if (song.album.isNotEmpty) song.album,
      if (song.year != null) song.year.toString(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            details.join('  ·  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CompactTypography.mono(
              theme.colorScheme.onSurfaceVariant,
              size: CompactTypeScale.mark,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ],
    );
  }
}

/// The facts the source published about the track.
///
/// Every source knows different things about a track, so the panel shows
/// whatever is known: the album, the year, the style, the quality of the
/// file, the licence and the station that plays it.
///
/// The facts are icons, not words: a row of facts keeps the same shape
/// whatever the values are. The mouse names a fact and the details panel
/// writes all of them down.
class _TrackDetails extends StatelessWidget {
  const _TrackDetails({required this.song, required this.source});

  final Song song;
  final SourceLabel? source;

  @override
  Widget build(BuildContext context) {
    final facts = trackFactsOf(context, song);
    if (facts.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.loc.nowPlayingDetails,
          style: CompactTypography.mono(
            theme.colorScheme.onSurfaceVariant,
            size: CompactTypeScale.mark,
            weight: FontWeight.w500,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final fact in facts)
              MetaBadge(
                icon: fact.icon,
                tooltip: fact.sentence,
                tone: fact.tone,
                size: 15,
                onTap: () =>
                    showTrackDetailSheet(context, song, source: source),
              ),
          ],
        ),
      ],
    );
  }
}
