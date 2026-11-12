import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/settings/presentation/settings_section_catalog.dart';

/// The buttons under the presets of [section].
List<Widget> settingsQuickActions(
  BuildContext context,
  SettingsSection section, {
  required bool libraryReady,
  required bool scanning,
  required bool clearing,
  required VoidCallback onScan,
  required VoidCallback onAddFolder,
  required bool canSetDefaultPlayer,
  required bool? isDefaultPlayer,
  required VoidCallback onSetDefaultPlayer,
}) {
  switch (section) {
    case SettingsSection.library:
      return [
        OutlinedButton.icon(
          onPressed: libraryReady && !scanning && !clearing ? onScan : null,
          style: _actionStyle(context),
          icon: const Icon(Icons.refresh_rounded, size: CompactTokens.icon16),
          label: Text(context.loc.libraryScanAllSources),
        ),
        const SizedBox(width: CompactTokens.space8),
        OutlinedButton.icon(
          onPressed: onAddFolder,
          style: _actionStyle(context),
          icon: const Icon(
            Icons.create_new_folder_outlined,
            size: CompactTokens.icon16,
          ),
          label: Text(context.loc.settingsAddFolder),
        ),
      ];
    case SettingsSection.desktop:
      if (!canSetDefaultPlayer) return const [];
      return [
        OutlinedButton.icon(
          onPressed: isDefaultPlayer == true ? null : onSetDefaultPlayer,
          style: _actionStyle(context),
          icon: const Icon(
            Icons.audiotrack_rounded,
            size: CompactTokens.icon16,
          ),
          label: Text(
            isDefaultPlayer == true
                ? context.loc.settingsDefaultPlayerActive
                : context.loc.settingsSetDefaultPlayer,
          ),
        ),
      ];
    default:
      return const [];
  }
}

ButtonStyle _actionStyle(BuildContext context) => OutlinedButton.styleFrom(
  minimumSize: const Size(0, CompactTokens.controlDefault),
  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
);
