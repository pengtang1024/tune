import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// Chip that names the source a track came from.
///
/// The chip is used by the library list, the queue list and the now playing
/// page so a remote source always reads the same way.
///
/// It carries two names in two colours: the big one is the name the source
/// writes itself with (a brand keeps its own spelling in every language), the
/// small one is what the source is called in the language of the reader. The
/// two names are one text, so the name of the source keeps its room and the
/// localized name gives way when the chip has too little of it.
class SourceChip extends StatelessWidget {
  final SourceLabel label;
  final bool dense;

  const SourceChip({super.key, required this.label, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final hasLocalizedName = label.localizedName.isNotEmpty;

    return TuneTooltip(
      message: hasLocalizedName
          ? '${label.name} · ${label.localizedName}'
          : label.name,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 6 : 8,
          vertical: dense ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(dense ? 5 : 6),
          border: Border.all(color: color.withValues(alpha: 0.26)),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                // Dart writes the upper case of a letter the same way in every
                // language, so the chip reads the same wherever the app runs.
                text: label.name.toUpperCase(),
                style: CompactTypography.mono(
                  color,
                  size: CompactTypeScale.mark,
                  weight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (hasLocalizedName)
                TextSpan(
                  text: ' · ${label.localizedName}',
                  style: TextStyle(
                    fontSize: CompactTypeScale.mark,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
