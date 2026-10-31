import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/app/theme/compact_tokens.dart';

/// The frame every group of settings sits in.
///
/// The groups of the settings page look the same, so the frame is written
/// once and only the content differs.
/// Says that the cards below are inside the custom sheet.
///
/// The sheet already names the section, so a card inside it drops its own
/// numbered header and shows only its controls.
class SettingsSheetScope extends InheritedWidget {
  final bool inSheet;

  const SettingsSheetScope({
    super.key,
    required this.inSheet,
    required super.child,
  });

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsSheetScope>()?.inSheet ??
      false;

  @override
  bool updateShouldNotify(SettingsSheetScope oldWidget) =>
      oldWidget.inSheet != inSheet;
}

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
    if (SettingsSheetScope.of(context)) {
      // The sheet has its own heading; the controls are all that is left.
      return Padding(
        padding: const EdgeInsets.only(bottom: CompactTokens.space8),
        child: child,
      );
    }

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
                  size: CompactTypeScale.mark,
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
                        theme.colorScheme.onSurfaceVariant,
                        size: CompactTypeScale.mark,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.labelMedium?.copyWith(
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
