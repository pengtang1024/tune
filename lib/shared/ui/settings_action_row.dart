import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';

/// A settings row that opens something instead of switching something.
///
/// The switch rows keep their shape; a row that leads to a panel says so with
/// a chevron and the same title/description rhythm, so the card does not
/// grow a second visual language.
class SettingsActionRow extends StatelessWidget {
  final String title;
  final String description;

  /// Null leaves the row readable but not openable — used when the platform
  /// has nothing behind it.
  final VoidCallback? onPressed;

  const SettingsActionRow({
    super.key,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(CompactTokens.space8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CompactTokens.space4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: enabled
                          ? null
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right_rounded,
              size: CompactTokens.icon20,
              color: enabled
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
