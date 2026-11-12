import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/settings/presentation/settings_section_catalog.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The rail on the left of the settings page.
class SettingsNavRail extends StatelessWidget {
  /// The sections the reader can go to, in order.
  final List<SettingsSection> sections;

  /// The section the page is showing.
  final SettingsSection selected;

  /// Whether the rail shows the labels beside the icons.
  final bool wide;

  final ValueChanged<SettingsSection> onSelected;

  const SettingsNavRail({
    super.key,
    required this.sections,
    required this.selected,
    required this.wide,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: wide ? 176 : 56,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          CompactTokens.space8,
          CompactTokens.space12,
          CompactTokens.space8,
          CompactTokens.space12,
        ),
        children: [
          if (sections.isEmpty)
            Padding(
              padding: const EdgeInsets.all(CompactTokens.space8),
              child: Text(
                context.loc.settingsSearchNoMatch,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final section in sections) ...[
            _tile(context, section),
            const SizedBox(height: CompactTokens.space4),
          ],
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, SettingsSection section) {
    final theme = Theme.of(context);
    final isSelected = selected == section;
    final tile = Material(
      color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: CompactTokens.borderRadius8,
      child: InkWell(
        key: ValueKey('settings-nav-${section.name}'),
        onTap: () => onSelected(section),
        borderRadius: CompactTokens.borderRadius8,
        child: Container(
          height: 36,
          padding: EdgeInsets.symmetric(
            horizontal: wide ? CompactTokens.space8 : 0,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 2,
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: wide
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                settingsSectionIcon(section),
                size: CompactTokens.icon18,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              if (wide) ...[
                const SizedBox(width: CompactTokens.space8),
                Expanded(
                  child: Text(
                    settingsSectionLabel(context, section),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (wide) return tile;
    return TuneTooltip(
      message: settingsSectionLabel(context, section),
      child: tile,
    );
  }
}
