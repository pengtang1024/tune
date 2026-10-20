import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/settings/presentation/settings_card_shell.dart';
import 'package:tune/features/settings/presentation/settings_switch_row.dart';

/// The settings of the playback.
///
/// The group holds the rules of what a click on a track means: a single
/// click decides whether the play queue survives, a double click decides
/// whether the track is only liked or played as well.
class SettingsPlaybackCard extends StatelessWidget {
  final bool replaceQueueOnClick;
  final bool onlyLikeOnDoubleClick;
  final ValueChanged<bool> onReplaceQueueOnClick;
  final ValueChanged<bool> onOnlyLikeOnDoubleClick;

  const SettingsPlaybackCard({
    super.key,
    required this.replaceQueueOnClick,
    required this.onlyLikeOnDoubleClick,
    required this.onReplaceQueueOnClick,
    required this.onOnlyLikeOnDoubleClick,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      index: '03',
      eyebrow: context.loc.settingsSectionPlayback,
      title: context.loc.settingsPlaybackTitle,
      description: context.loc.settingsPlaybackDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSwitchRow(
            title: context.loc.settingsReplaceQueueOnClick,
            description: context.loc.settingsReplaceQueueOnClickHint,
            value: replaceQueueOnClick,
            onChanged: onReplaceQueueOnClick,
          ),
          const SizedBox(height: 8),
          SettingsSwitchRow(
            title: context.loc.settingsOnlyLikeOnDoubleClick,
            description: context.loc.settingsOnlyLikeOnDoubleClickHint,
            value: onlyLikeOnDoubleClick,
            onChanged: onOnlyLikeOnDoubleClick,
          ),
        ],
      ),
    );
  }
}
