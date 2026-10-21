import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/meta_badge.dart';
import 'package:tune/shared/ui/track_facts.dart';

/// The facts of a track that fit into a list row.
///
/// The strip keeps the words out of the row: every fact is an icon, and the
/// tooltip says what the icon means. A reader who wants the words opens the
/// details of the track.
class TrackFactStrip extends StatelessWidget {
  final Song song;

  const TrackFactStrip({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final facts = rowFactsOf(context, song);
    if (facts.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The badges stand next to each other with a hair of room, so the
        // eye reads them as one row of marks.
        for (final (index, fact) in facts.indexed) ...[
          if (index > 0) const SizedBox(width: CompactTokens.space4),
          MetaBadge(icon: fact.icon, tooltip: fact.sentence, tone: fact.tone),
        ],
      ],
    );
  }
}
