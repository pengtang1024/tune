import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/compact_sheet.dart';
import 'package:tune/shared/ui/track_addresses.dart';
import 'package:tune/shared/ui/track_detail_block.dart';
import 'package:tune/shared/ui/track_detail_columns.dart';
import 'package:tune/shared/ui/track_detail_header.dart';
import 'package:tune/shared/ui/track_detail_row.dart';
import 'package:tune/shared/ui/track_detail_table.dart';
import 'package:tune/shared/ui/track_facts.dart';

/// The room the panel keeps inside its edges.
const EdgeInsets _panelPadding = EdgeInsets.fromLTRB(
  CompactTokens.space20,
  CompactTokens.space16,
  CompactTokens.space20,
  CompactTokens.space24,
);

/// Shows everything that is known about a track.
///
/// The sheet is the one place where all the facts of a track stand together,
/// so a reader can look a track up instead of guessing what it is.
///
/// The panel is as wide as its own words: the table of the facts is measured
/// from the words that go in it, and the panel stops growing there. A panel
/// that reaches for the whole width of the window leaves a stretch of nothing
/// beside the values, and that emptiness is what makes a panel look thin.
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

    // The columns are measured from the words that go in them, so the table
    // is exactly as wide as the words need and not a pixel more.
    final columns = TrackDetailColumns.of(
      context,
      [...rows, ...addresses],
      maxWidth: CompactTokens.detailPanelWidth - _panelPadding.horizontal,
    );

    return SizedBox(
      key: const ValueKey('track-detail-panel'),
      width: _panelWidth(context, columns),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(CompactTokens.sheetRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: _panelPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TrackDetailHeader(
                song: song,
                isFavorite: isFavorite,
                onToggleFavorite: onToggleFavorite,
              ),
              if (rows.isNotEmpty || addresses.isNotEmpty) ...[
                const SizedBox(height: CompactTokens.space14),
                TrackDetailTable(
                  columns: columns,
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
                const SizedBox(height: CompactTokens.space14),
                TrackDetailBlockView(block: block),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The width of the panel.
  ///
  /// The panel is as wide as the table of the facts or as the head above it,
  /// whichever is wider, and never wider than the window allows.
  double _panelWidth(BuildContext context, TrackDetailColumns columns) {
    final table = columns.name + CompactTokens.space12 + columns.value;
    final title = song.title.isEmpty
        ? context.loc.trackUnknownTitle
        : song.title;
    final artist = song.artist.isEmpty
        ? context.loc.playerUnknownArtist
        : song.artist;
    final head = trackDetailHeaderWidth(
      context,
      title,
      artist,
      hasHeart: onToggleFavorite != null,
    );

    return math.min(
      math.max(table, head) + _panelPadding.horizontal,
      CompactTokens.detailPanelWidth,
    );
  }
}
