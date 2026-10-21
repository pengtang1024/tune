import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/compact_sheet.dart';
import 'package:tune/shared/ui/track_addresses.dart';
import 'package:tune/shared/ui/track_detail_block.dart';
import 'package:tune/shared/ui/track_detail_row.dart';
import 'package:tune/shared/ui/track_detail_table.dart';
import 'package:tune/shared/ui/track_facts.dart';

/// Shows everything that is known about a track.
///
/// The sheet is the one place where all the facts of a track stand together,
/// so a reader can look a track up instead of guessing what it is.
Future<void> showTrackDetailSheet(
  BuildContext context,
  Song song, {
  SourceLabel? source,
}) {
  return showCompactSheet<void>(
    context,
    (context) => _TrackDetailSheet(song: song, source: source),
  );
}

class _TrackDetailSheet extends StatelessWidget {
  final Song song;
  final SourceLabel? source;

  const _TrackDetailSheet({required this.song, this.source});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facts = trackFactsOf(context, song, source: source);

    // A text too long for a line is written out as a paragraph of its own,
    // under the name it has in the facts.
    final paragraphs = [
      for (final fact in facts.where((fact) => fact.paragraph))
        TrackDetailBlock(label: fact.label, text: fact.value),
    ];
    final rows = [
      for (final fact in facts.where((fact) => !fact.paragraph))
        TrackDetailRow(
          label: fact.label,
          icon: fact.icon,
          value: fact.value,
          tone: fact.tone,
          machine: fact.machine,
        ),
    ];
    final addresses = trackAddressRows(context, song);
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
            _Header(song: song),
            if (rows.isNotEmpty || addresses.isNotEmpty) ...[
              const SizedBox(height: CompactTokens.space20),
              TrackDetailTable(
                sections: [
                  TrackDetailSection(rows: rows),
                  TrackDetailSection(
                    heading: context.loc.trackDetailsAddresses,
                    rows: addresses,
                  ),
                ],
              ),
            ],
            for (final block in blocks) ...[
              const SizedBox(height: CompactTokens.space20),
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

  const _Header({required this.song});

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
        const SizedBox(width: 12),
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
              const SizedBox(height: 4),
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
      ],
    );
  }
}
