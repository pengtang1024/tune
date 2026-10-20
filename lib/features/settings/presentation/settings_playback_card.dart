import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/settings/presentation/settings_card_shell.dart';
import 'package:tune/features/settings/presentation/settings_switch_row.dart';

/// The settings of the playback.
///
/// The group holds the rule of what a single click on a track means, because
/// it decides whether the play queue survives the click.
class SettingsPlaybackCard extends StatelessWidget {
  final bool replaceQueueOnClick;
  final ValueChanged<bool> onReplaceQueueOnClick;

  const SettingsPlaybackCard({
    super.key,
    required this.replaceQueueOnClick,
    required this.onReplaceQueueOnClick,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      index: '03',
      eyebrow: context.loc.settingsSectionPlayback,
      title: context.loc.settingsPlaybackTitle,
      description: context.loc.settingsPlaybackDescription,
      child: SettingsSwitchRow(
        title: context.loc.settingsReplaceQueueOnClick,
        description: context.loc.settingsReplaceQueueOnClickHint,
        value: replaceQueueOnClick,
        onChanged: onReplaceQueueOnClick,
      ),
    );
  }
}
