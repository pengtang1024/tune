import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// What a track is, in the reader's language.
///
/// A song needs no name: the library is mostly songs, so the missing mark
/// says the track is one. Everything else says what it is, because a row of
/// an episode, a chapter, a station and a sound effect would otherwise look
/// exactly like a row of a song.
String? contentKindLabelOf(BuildContext context, Song song) {
  return switch (contentKindOf(song)) {
    ContentKind.music => null,
    ContentKind.podcast => context.loc.contentKindPodcast,
    ContentKind.audiobook => context.loc.contentKindAudiobook,
    ContentKind.radio => context.loc.contentKindRadio,
    ContentKind.soundEffect => context.loc.contentKindSoundEffect,
  };
}

/// The icon of the mark that names a speech track, or null for the rest.
///
/// The row writes the word for every kind, but only a speech track gets an
/// icon in the facts strip: a station already says it is live in its tail,
/// and a sound effect says it with its length.
IconData? contentKindIconOf(Song song) {
  if (!contentKindOf(song).isSpokenWord) return null;
  return Icons.record_voice_over_rounded;
}

/// The word beside the title of a track that is not a song.
///
/// It writes the word, not just an icon: a reader should be able to tell an
/// episode from a chapter from a station without hovering. A song has no
/// word — the missing word says it is one, and writing 「音乐」 on five
/// thousand rows would say nothing.
///
/// The word is plain text, not a chip: [docs/chips.md] keeps the chips that
/// write a fact for the details panel, and a row only carries the name of
/// what it is.
///
/// Clicking the word narrows the page to that content kind, which is the
/// other half of telling rows apart: the word names what the row is, and
/// takes the reader to the rest of that kind.
class ContentKindMark extends StatelessWidget {
  final Song song;

  /// Called when the reader clicks the word; null leaves it inert.
  final VoidCallback? onOpenKind;

  const ContentKindMark({super.key, required this.song, this.onOpenKind});

  @override
  Widget build(BuildContext context) {
    final label = contentKindLabelOf(context, song);
    if (label == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final word = Padding(
      padding: const EdgeInsets.only(left: CompactTokens.space6),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CompactTypography.mono(
          theme.colorScheme.onSurfaceVariant,
          size: CompactTypeScale.mark,
          letterSpacing: 0.3,
        ),
      ),
    );

    return TuneTooltip(
      message: onOpenKind == null
          ? label
          : '$label · ${context.loc.libraryShowKindOnly}',
      child: onOpenKind == null
          ? word
          : InkWell(
              onTap: onOpenKind,
              borderRadius: BorderRadius.circular(CompactTokens.radius6),
              child: word,
            ),
    );
  }
}
