import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/discovery/application/discovery_controller.dart';
import 'package:tune/features/discovery/application/discovery_providers.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_switch_row.dart';
import 'package:tune/features/settings/presentation/settings_card_shell.dart';

/// The settings of the discover page.
///
/// The page keeps no profile and no history of its own; the marks it keeps
/// are the only thing a reader may want to take back. The card says where the
/// picks come from and gives that one action.
class SettingsDiscoveryCard extends ConsumerWidget {
  const SettingsDiscoveryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final useHistory = ref.watch(
      settingsControllerProvider.select((state) => state.useListeningHistory),
    );

    return SettingsCard(
      index: '04',
      eyebrow: context.loc.settingsSectionDiscovery,
      title: context.loc.settingsDiscoveryTitle,
      description: context.loc.settingsDiscoveryDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSwitchRow(
            title: context.loc.settingsDiscoveryUseHistory,
            description: context.loc.settingsDiscoveryUseHistoryHint,
            value: useHistory,
            onChanged: (value) => ref
                .read(settingsControllerProvider.notifier)
                .setUseListeningHistory(value),
          ),
          const SizedBox(height: CompactTokens.space12),
          Text(
            context.loc.settingsDiscoveryPrivacy,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: CompactTokens.space12),
          OutlinedButton.icon(
            key: const ValueKey('settings-discovery-clear'),
            onPressed: () => _clear(context, ref),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, CompactTokens.controlDefault),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: CompactTokens.icon16,
            ),
            label: Text(context.loc.discoverClearAll),
          ),
        ],
      ),
    );
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.discoverClearTitle),
        content: Text(context.loc.discoverClearMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.loc.clear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(discoveryFeedbackStoreProvider).clear();
    await ref.read(listeningSignalStoreProvider).clear();
    ref.invalidate(discoveryControllerProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.loc.discoverCleared),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}
