import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_typography.dart';

/// The frame every group of settings sits in.
///
/// The groups of the settings page look the same, so the frame is written
/// once and only the content differs.
class SettingsCard extends StatelessWidget {
  final String index;
  final String eyebrow;
  final String title;
  final String description;
  final Widget child;
  final Widget? trailing;

  const SettingsCard({
    super.key,
    required this.index,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                index,
                style: CompactTypography.mono(
                  theme.colorScheme.primary,
                  size: 9,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 9),
              Container(
                width: 1,
                height: 32,
                color: theme.colorScheme.outlineVariant,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: CompactTypography.mono(
                        theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.65,
                        ),
                        size: 8,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
