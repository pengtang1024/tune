import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';

/// Action that puts the whole visible list into the play queue.
///
/// A track of the library is played on its own, so a library with thousands
/// of tracks only reaches the queue when the user asks for it.
class LibraryQueueAllButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const LibraryQueueAllButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      tooltip: context.loc.libraryAddAllToQueue,
      onPressed: onPressed,
      icon: const Icon(Icons.queue_music_rounded, size: CompactTokens.icon18),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      style: IconButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
