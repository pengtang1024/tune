import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/settings/presentation/settings_card_shell.dart';

/// The settings of the desktop integration.
///
/// The group holds the two switches that decide how the player behaves when
/// the window is gone, and the action that makes Tune the program the
/// desktop opens audio files with.
class SettingsDesktopCard extends StatelessWidget {
  final bool closeToTray;
  final bool mediaControlsEnabled;
  final bool isDefaultPlayer;

  /// Whether the desktop entry of Tune is in place.
  ///
  /// The desktop only accepts a program it knows, so without the entry the
  /// action cannot work and the button stays out of the way.
  final bool desktopEntryInstalled;
  final ValueChanged<bool> onCloseToTrayChanged;
  final ValueChanged<bool> onMediaControlsChanged;
  final VoidCallback? onSetDefaultPlayer;

  const SettingsDesktopCard({
    super.key,
    required this.closeToTray,
    required this.mediaControlsEnabled,
    required this.isDefaultPlayer,
    required this.desktopEntryInstalled,
    required this.onCloseToTrayChanged,
    required this.onMediaControlsChanged,
    required this.onSetDefaultPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SettingsCard(
      index: '03',
      eyebrow: context.loc.settingsSectionDesktop,
      title: context.loc.settingsDesktopTitle,
      description: context.loc.settingsDesktopDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SwitchRow(
            title: context.loc.settingsCloseToTray,
            description: context.loc.settingsCloseToTrayHint,
            value: closeToTray,
            onChanged: onCloseToTrayChanged,
          ),
          const SizedBox(height: 8),
          _SwitchRow(
            title: context.loc.settingsMediaControls,
            description: context.loc.settingsMediaControlsHint,
            value: mediaControlsEnabled,
            onChanged: onMediaControlsChanged,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onSetDefaultPlayer,
                icon: const Icon(Icons.album_outlined, size: CompactTokens.icon16),
                label: Text(context.loc.settingsSetDefaultPlayer),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, CompactTokens.controlDefault),
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                ),
              ),
              if (isDefaultPlayer) ...[
                const SizedBox(width: 10),
                Icon(
                  Icons.check_circle_outline,
                  size: CompactTokens.icon14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  context.loc.settingsDefaultPlayerActive,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          if (!desktopEntryInstalled) ...[
            const SizedBox(height: 6),
            Text(
              context.loc.settingsDefaultPlayerMissingEntry,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A switch with the text that explains it.
class _SwitchRow extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
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
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
