import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/library/presentation/library_queue_all_button.dart';

/// The compact heading of the library.
///
/// The library is the page a reader lives on while looking for a track, so
/// its heading shares one line with the counts and the two actions instead
/// of taking three lines above the list. The title keeps the display face:
/// the page still says who it is, it just does not spend a whole track row
/// on saying it.
class LibraryHeader extends StatelessWidget {
  /// What the library holds: tracks, albums and sources.
  final String summary;

  /// Puts the whole visible list into the queue.
  final VoidCallback? onAddAll;
  final VoidCallback onSearchOnline;

  const LibraryHeader({
    super.key,
    required this.summary,
    required this.onAddAll,
    required this.onSearchOnline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = CompactTypography.asDisplay(
      theme.textTheme.displayMedium,
      size: CompactTypeScale.displayMedium,
      height: 0.95,
    );

    return SizedBox(
      height: CompactTokens.controlDefault,
      child: Row(
        children: [
          Text(
            context.loc.libraryEyebrow,
            style: CompactTypography.mono(
              theme.colorScheme.primary,
              size: CompactTypeScale.mark,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: CompactTokens.space8),
          Text(context.loc.libraryTitle, style: titleStyle),
          const SizedBox(width: CompactTokens.space12),
          Expanded(
            child: Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: CompactTokens.space12),
          LibraryQueueAllButton(onPressed: onAddAll),
          const SizedBox(width: CompactTokens.space8),
          OutlinedButton.icon(
            onPressed: onSearchOnline,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, CompactTokens.controlDefault),
              padding: const EdgeInsets.symmetric(
                horizontal: CompactTokens.space12,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            icon: const Icon(
              Icons.travel_explore_rounded,
              size: CompactTokens.icon16,
            ),
            label: Text(context.loc.searchOnlineTitle),
          ),
        ],
      ),
    );
  }
}
