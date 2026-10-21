import 'package:flutter/material.dart';

/// The name of a group of lines.
///
/// The name stands above the group in a heavier face than the names of the
/// table, so the reader sees the groups before the lines.
class TrackDetailHeading extends StatelessWidget {
  final String text;

  const TrackDetailHeading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}
