import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The mark that tells the reader the track never ends.
///
/// The mark is an icon, not a word: a chip that carries its word grows and
/// shrinks with the word, and the dock has no room for that. The mouse says
/// what the mark means.
///
/// The dock and the now playing page share this mark, so a live track reads
/// the same way in both.
class LiveBadge extends StatelessWidget {
  final bool dense;

  const LiveBadge({super.key, this.dense = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.tertiary;

    return TuneTooltip(
      message: context.loc.playerLiveBadge,
      child: Container(
        width: dense ? 18 : 22,
        height: dense ? 18 : 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(dense ? 5 : 6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(
          Icons.podcasts_rounded,
          size: dense ? CompactTokens.icon12 : CompactTokens.icon14,
          color: color,
        ),
      ),
    );
  }
}
