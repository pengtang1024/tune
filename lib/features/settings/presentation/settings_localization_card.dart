import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/translation/translation_provider_catalog.dart';
import 'package:tune/domain/models/localization_config.dart';
import 'package:tune/domain/models/translation_provider.dart';
import 'package:tune/features/localization/application/local_model_controller.dart';
import 'package:tune/features/localization/application/localization_providers.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_localization_ledger.dart';
import 'package:tune/features/settings/presentation/settings_localization_local_block.dart';
import 'package:tune/features/settings/presentation/settings_localization_picker.dart';
import 'package:tune/features/settings/presentation/settings_localization_provider_block.dart';
import 'package:tune/shared/ui/settings_card_shell.dart';
import 'package:tune/shared/ui/settings_switch_row.dart';

/// The switch, the vendor and the optional local model of translation.
class SettingsLocalizationCard extends ConsumerStatefulWidget {
  const SettingsLocalizationCard({super.key});

  @override
  ConsumerState<SettingsLocalizationCard> createState() =>
      _SettingsLocalizationCardState();
}

class _SettingsLocalizationCardState
    extends ConsumerState<SettingsLocalizationCard> {
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _model;
  late String _syncedBackend;

  @override
  void initState() {
    super.initState();
    final config = ref.read(settingsControllerProvider).localization;
    _syncedBackend = config.backendId;
    final credential = config.activeCredential;
    final provider = providerById(config.backendId);
    _baseUrl = TextEditingController(text: credential.baseUrl);
    _apiKey = TextEditingController(text: credential.apiKey);
    _model = TextEditingController(
      text: credential.model.isNotEmpty
          ? credential.model
          : provider?.defaultModel ?? '',
    );
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _apiKey.dispose();
    _model.dispose();
    super.dispose();
  }

  void _applyCredential(LocalizationConfig config) {
    if (_syncedBackend == config.backendId) return;
    final credential = config.credentialFor(config.backendId);
    final provider = providerById(config.backendId);
    _baseUrl.text = credential.baseUrl;
    _apiKey.text = credential.apiKey;
    _model.text = credential.model.isNotEmpty
        ? credential.model
        : provider?.defaultModel ?? '';
    _syncedBackend = config.backendId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final config = ref.watch(
      settingsControllerProvider.select((settings) => settings.localization),
    );
    ref.listen(
      settingsControllerProvider.select((settings) => settings.localization),
      (previous, next) {
        if (previous?.backendId != next.backendId) _applyCredential(next);
      },
    );
    final availability = ref.watch(translationAvailabilityProvider);
    final provider = providerById(config.backendId);
    final isLocal = provider?.isLocalModel ?? false;
    final isVendor = provider != null && !provider.isLocalModel;
    final balance = isVendor && provider.supportsBalance
        ? ref.watch(translationBalanceProvider)
        : null;
    final extraModels = provider?.id == 'ollama'
        ? ref.watch(ollamaModelsProvider).value ?? const <String>[]
        : const <String>[];
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
          if (config.enabled && availability != TranslationAvailability.available)
            SettingsLocalizationAvailabilityNotice(availability: availability),
          const SizedBox(height: CompactTokens.space16),
          Text(
            strings.settingsLocalizationProvider,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: CompactTokens.space8),
          SettingsLocalizationProviderPicker(
            value: config.backendId,
            onChanged: (id) => unawaited(_selectBackend(id, config)),
          ),
          const SizedBox(height: CompactTokens.space16),
          if (isLocal)
            SettingsLocalizationLocalBlock(
              state: ref.watch(localModelControllerProvider),
              onDownload: () =>
                  ref.read(localModelControllerProvider.notifier).download(),
              onCancel: () =>
                  ref.read(localModelControllerProvider.notifier).cancelDownload(),
              onRemove: () =>
                  ref.read(localModelControllerProvider.notifier).remove(),
            )
          else if (isVendor)
            SettingsLocalizationProviderBlock(
              provider: provider,
              baseUrl: _baseUrl,
              apiKey: _apiKey,
              model: _model,
              extraModels: extraModels,
              balance: balance?.value,
              onSave: () => controller.setLocalization(
                config.withCredential(
                  provider.id,
                  ProviderCredential(
                    apiKey: _apiKey.text.trim(),
                    model: _model.text.trim(),
                    baseUrl: _baseUrl.text.trim(),
                  ),
                ),
              ),
              onCheckBalance: () =>
                  ref.read(translationBalanceRequestProvider.notifier).state++,
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
      final accepted = await _confirmPrivacy(
        provider?.name ?? context.loc.settingsLocalizationProviderNone,
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

  Future<void> _selectBackend(
    String? id,
    LocalizationConfig config,
  ) async {
    if (id == null || id == config.backendId) return;
    final provider = providerById(id);
    final controller = ref.read(settingsControllerProvider.notifier);
    if (provider == null) {
      controller.setLocalization(config.copyWith(backendId: ''));
      return;
    }
    var accepted = config.privacyAccepted;
    if (!provider.isLocalModel && !accepted) {
      accepted = await _confirmPrivacy(provider.name);
      if (!accepted || !mounted) return;
    }
    final existing = config.credentialFor(provider.id);
    final credential = existing.model.trim().isEmpty &&
            provider.defaultModel.trim().isNotEmpty
        ? existing.copyWith(model: provider.defaultModel)
        : existing;
    final next = config
        .withCredential(provider.id, credential)
        .copyWith(backendId: provider.id, privacyAccepted: accepted);
    controller.setLocalization(next);
    _applyCredential(next);
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
