import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';

/// Heading of a page in the compact desktop shell.
///
/// Every page uses the same three part rhythm: a mono eyebrow that names the
/// section, a Fraunces display title and a short sentence in the subtitle.
class PageHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const PageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eyebrow,
                style: CompactTypography.mono(
                  theme.colorScheme.primary,
                  size: CompactTypeScale.mark,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: CompactTypography.asDisplay(
                  theme.textTheme.displayMedium,
                  size: CompactTokens.pageTitleSize,
                  height: 0.95,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 16), trailing!],
      ],
    );
  }
}
