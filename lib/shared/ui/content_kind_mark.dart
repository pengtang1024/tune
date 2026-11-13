import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/meta_badge.dart';
import 'package:tune/shared/ui/track_fact.dart';

/// The name of what a speech track is, in the reader's language.
///
/// A song needs no name: the library is mostly songs, so the missing mark
/// says the track is one. A station says it is live in its tail, so the mark
/// is left for podcasts and audiobooks.
String? contentKindLabelOf(BuildContext context, Song song) {
  return switch (contentKindOf(song)) {
    ContentKind.podcast => context.loc.contentKindPodcast,
    ContentKind.audiobook => context.loc.contentKindAudiobook,
    _ => null,
  };
}

/// The icon of the mark that names a speech track, or null for the rest.
IconData? contentKindIconOf(Song song) {
  if (!contentKindOf(song).isSpokenWord) return null;
  return Icons.record_voice_over_rounded;
}

/// The mark beside the title of a speech track.
///
/// It writes no words, so it fits in a table row and in a two-line card
/// without moving anything: the name waits in the tooltip. It carries its
/// own left gap so a row can drop it in without asking whether the track is
/// speech.
class ContentKindMark extends StatelessWidget {
  final Song song;
  final double size;

  const ContentKindMark({super.key, required this.song, this.size = 14});

  @override
  Widget build(BuildContext context) {
    final icon = contentKindIconOf(song);
    final label = contentKindLabelOf(context, song);
    if (icon == null || label == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: CompactTokens.space4),
      child: MetaBadge(
        icon: icon,
        tooltip: label,
        tone: FactTone.secondary,
        size: size,
      ),
    );
  }
}
