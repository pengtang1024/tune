import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/compact_sheet.dart';
import 'package:tune/shared/ui/favorite_button.dart';
import 'package:tune/shared/ui/meta_badge.dart';
import 'package:tune/shared/ui/track_addresses.dart';
import 'package:tune/shared/ui/track_detail_block.dart';
import 'package:tune/shared/ui/track_facts.dart';

/// Shows everything that is known about a track.
///
/// The sheet is the one place where all the facts of a track stand together,
/// so a reader can look a track up instead of guessing what it is.
///
/// The facts stand in chips, one chip per fact: the icon says which fact it
/// is and the chip writes its value. The addresses are the one thing a chip
/// cannot carry in writing — they are longer than a line — so each of them
/// names itself and hands its address to a chip of its own.
///
/// The heart marks the track as one of the favorites. The sheet is a shared
/// piece of the interface and knows nothing about the favorites, so the
/// caller says whether the track is one of them and what a click does.
Future<void> showTrackDetailSheet(
  BuildContext context,
  Song song, {
  SourceLabel? source,
  bool isFavorite = false,
  VoidCallback? onToggleFavorite,
}) {
  return showCompactSheet<void>(
    context,
    (context) => _TrackDetailSheet(
      song: song,
      source: source,
      isFavorite: isFavorite,
      onToggleFavorite: onToggleFavorite,
    ),
  );
}

class _TrackDetailSheet extends StatelessWidget {
  final Song song;
  final SourceLabel? source;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const _TrackDetailSheet({
    required this.song,
    this.source,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facts = trackFactsOf(context, song, source: source);

    // A text too long for a chip is written out as a paragraph of its own,
    // under the name it has in the facts.
    final paragraphs = [
      for (final fact in facts.where((fact) => fact.paragraph))
        TrackDetailBlock(label: fact.label, text: fact.value),
    ];
    final chips = [
      for (final fact in facts.where((fact) => !fact.paragraph))
        MetaChip(
          icon: fact.icon,
          value: fact.value,
          tooltip: fact.sentence,
          tone: fact.tone,
        ),
    ];
    final blocks = [...paragraphs, ...trackDetailBlocksOf(context, song)];

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(CompactTokens.sheetRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          CompactTokens.space20,
          CompactTokens.space16,
          CompactTokens.space20,
          CompactTokens.space24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              song: song,
              isFavorite: isFavorite,
              onToggleFavorite: onToggleFavorite,
            ),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: CompactTokens.space16),
              Wrap(
                spacing: CompactTokens.space6,
                runSpacing: CompactTokens.space6,
                children: chips,
              ),
            ],
            const SizedBox(height: CompactTokens.space18),
            TrackAddresses(song: song),
            for (final block in blocks) ...[
              const SizedBox(height: CompactTokens.space18),
              TrackDetailBlockView(block: block),
            ],
          ],
        ),
      ),
    );
  }
}

/// The track the sheet belongs to.
class _Header extends StatelessWidget {
  final Song song;

  /// Whether the track is one of the favorites.
  final bool isFavorite;

  /// What the click on the heart does.
  final VoidCallback? onToggleFavorite;

  const _Header({
    required this.song,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ArtworkThumb(
          path: song.albumArtPath,
          imageUrl: song.artworkUrl,
          size: CompactTokens.artworkHero,
          radius: 12,
        ),
        const SizedBox(width: CompactTokens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                song.title.isEmpty ? context.loc.trackUnknownTitle : song.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CompactTypography.asDisplay(
                  theme.textTheme.titleMedium,
                  size: CompactTypeScale.displaySmall,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: CompactTokens.space4),
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
        // The heart only shows when there is something to mark: the sheet is
        // a shared piece of the interface, and the caller decides whether the
        // track can be marked here.
        if (onToggleFavorite case final action?)
          FavoriteButton(isFavorite: isFavorite, onPressed: action),
      ],
    );
  }
}
