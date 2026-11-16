import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/translation/translation_provider_catalog.dart';
import 'package:tune/domain/models/localization_config.dart';
import 'package:tune/domain/models/translation_provider.dart';
import 'package:tune/features/localization/application/localization_providers.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_localization_ledger.dart';
import 'package:tune/features/settings/presentation/settings_localization_notices.dart';
import 'package:tune/features/settings/presentation/settings_translation_vendors_dialog.dart';
import 'package:tune/features/settings/presentation/settings_translation_vendors_labels.dart';
import 'package:tune/shared/ui/settings_card_shell.dart';
import 'package:tune/shared/ui/settings_switch_row.dart';

/// The switch, the chosen vendor and the optional local model of translation.
///
/// The vendor itself is configured on its own page
/// ([showTranslationVendorsDialog]): there are too many services, plans and
/// quirks to keep inline, and the card only needs to say who is chosen.
class SettingsLocalizationCard extends ConsumerStatefulWidget {
  const SettingsLocalizationCard({super.key});

  @override
  ConsumerState<SettingsLocalizationCard> createState() =>
      _SettingsLocalizationCardState();
}

class _SettingsLocalizationCardState
    extends ConsumerState<SettingsLocalizationCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final config = ref.watch(
      settingsControllerProvider.select((settings) => settings.localization),
    );
    final availability = ref.watch(translationAvailabilityProvider);
    final provider = providerById(config.backendId);
    final credential = config.activeCredential;
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return SettingsCard(
      index: '08',
      eyebrow: strings.settingsSectionLocalization,
      title: strings.settingsLocalizationTitle,
      description: strings.settingsLocalizationDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSwitchRow(
            title: strings.settingsLocalizationEnable,
            description: strings.settingsLocalizationEnableHint,
            value: config.enabled,
            onChanged: (value) =>
                unawaited(_setEnabled(value, config, provider)),
          ),
          const SizedBox(height: CompactTokens.space12),
          SettingsSwitchRow(
            title: strings.settingsLocalizationShowOriginal,
            description: strings.settingsLocalizationShowOriginalHint,
            value: config.showOriginal,
            onChanged: (value) => controller.setLocalization(
              config.copyWith(showOriginal: value),
            ),
          ),
          if (config.enabled &&
              availability != TranslationAvailability.available)
            SettingsLocalizationAvailabilityNotice(availability: availability),
          const SizedBox(height: CompactTokens.space16),
          Text(
            strings.settingsLocalizationProvider,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: CompactTokens.space8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider == null
                          ? strings.settingsLocalizationProviderNone
                          : translationVendorName(strings, provider),
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (provider != null)
                      Text(
                        provider.isCustom
                            ? (credential.baseUrl.isEmpty
                                  ? strings.settingsLocalizationApiBaseUrl
                                  : credential.baseUrl)
                            : provider.baseUrl,
                        style: muted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: CompactTokens.space8),
              OutlinedButton(
                onPressed: () => unawaited(showTranslationVendorsDialog(context)),
                child: Text(strings.settingsLocalizationVendorsOpen),
              ),
            ],
          ),
          const SizedBox(height: CompactTokens.space16),
          SettingsLocalizationLedger(
            tokens: ref.watch(translationTokenUsageProvider).value?.total,
            cached: ref.watch(translationCacheCountProvider).value,
            onClear: () async {
              final store = await ref.read(translationStoreProvider.future);
              store.clear();
              ref.invalidate(translationCacheCountProvider);
            },
          ),
          const SizedBox(height: CompactTokens.space12),
          const SettingsLocalizationPrivacyNotice(),
        ],
      ),
    );
  }

  Future<void> _setEnabled(
    bool value,
    LocalizationConfig config,
    TranslationProvider? provider,
  ) async {
    if (!value) {
      ref
          .read(settingsControllerProvider.notifier)
          .setLocalization(config.copyWith(enabled: false));
      return;
    }
    if (!config.privacyAccepted && !(provider?.isLocalModel ?? false)) {
      final strings = context.loc;
      final accepted = await _confirmPrivacy(
        provider == null
            ? strings.settingsLocalizationProviderNone
            : translationVendorName(strings, provider),
      );
      if (!accepted || !mounted) return;
      ref
          .read(settingsControllerProvider.notifier)
          .setLocalization(
            config.copyWith(enabled: true, privacyAccepted: true),
          );
      return;
    }
    ref
        .read(settingsControllerProvider.notifier)
        .setLocalization(config.copyWith(enabled: true));
  }

  Future<bool> _confirmPrivacy(String providerName) async {
    final strings = context.loc;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.settingsLocalizationConfirmTitle(providerName)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.settingsLocalizationConfirmBody),
            const SizedBox(height: CompactTokens.space12),
            Text(strings.settingsLocalizationPrivacySend),
            const SizedBox(height: CompactTokens.space4),
            Text(strings.settingsLocalizationPrivacyKeep),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.settingsLocalizationConfirmAccept),
          ),
        ],
      ),
    );
    return accepted ?? false;
  }
}
