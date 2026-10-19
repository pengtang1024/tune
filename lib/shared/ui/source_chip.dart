import 'package:flutter/material.dart';

/// Mono label that names the source a track came from.
///
/// The chip is used by the library list, the queue list and the now playing
/// page so a remote source always reads the same way.
class SourceChip extends StatelessWidget {
  final String label;
  final bool dense;

  const SourceChip({super.key, required this.label, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 6 : 8,
          vertical: dense ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(dense ? 5 : 6),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.26),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: dense ? 7.5 : 8.5,
            letterSpacing: dense ? 0.5 : 0.8,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
