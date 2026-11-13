import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/settings/presentation/settings_permissions_card.dart';
import 'package:tune/features/settings/presentation/settings_presets.dart';
import 'package:tune/features/settings/presentation/settings_section_catalog.dart';
import 'package:tune/features/settings/presentation/settings_source_health_card.dart';
import 'package:tune/shared/ui/settings_card_shell.dart';

/// One card of the settings page: its title, its presets, its actions and its
/// body.
class SettingsSectionCard extends StatelessWidget {
  final SettingsSection section;
  final List<SettingsPreset> presets;
  final String selectedPresetId;
  final List<Widget> actions;

  /// Opens the customize sheet (or the health weights, for the health card).
  final VoidCallback onCustomize;

  const SettingsSectionCard({
    super.key,
    required this.section,
    required this.presets,
    required this.selectedPresetId,
    required this.actions,
    required this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsPanel(
      key: ValueKey('settings-card-${section.name}'),
      icon: settingsSectionIcon(section),
      title: settingsSectionLabel(context, section),
      trailing: section == SettingsSection.permissions
          ? null
          : TextButton(
              key: ValueKey('settings-customize-${section.name}'),
              onPressed: onCustomize,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(context.loc.settingsCustomize),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section == SettingsSection.permissions)
            const SettingsPermissionsCard(),
          if (section == SettingsSection.sourceHealth)
            const SettingsSourceHealthCard(embedded: true),
          if (presets.isNotEmpty)
            Wrap(
              spacing: CompactTokens.space6,
              runSpacing: CompactTokens.space6,
              children: [
                for (final preset in presets)
                  ChoiceChip(
                    label: Text(preset.title),
                    avatar: Icon(preset.icon, size: CompactTokens.icon14),
                    selected: preset.id == selectedPresetId,
                    onSelected: (_) => preset.apply(),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          if (presets.isNotEmpty && actions.isNotEmpty)
            const SizedBox(height: CompactTokens.space8),
          if (actions.isNotEmpty)
            Wrap(spacing: CompactTokens.space8, children: actions),
        ],
      ),
    );
  }
}
