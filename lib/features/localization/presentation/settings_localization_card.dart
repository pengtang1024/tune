import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/translation/translation_balance.dart';
import 'package:tune/features/localization/application/local_model_controller.dart';
import 'package:tune/features/localization/application/localization_providers.dart';
import 'package:tune/features/localization/domain/localization_config.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/shared/ui/settings_card_shell.dart';
import 'package:tune/shared/ui/settings_switch_row.dart';

/// The switch and the engine of the automatic metadata translation.
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

  @override
  void initState() {
    super.initState();
    final config = ref.read(settingsControllerProvider).localization;
    _baseUrl = TextEditingController(text: config.apiBaseUrl);
    _apiKey = TextEditingController(text: config.apiKey);
    _model = TextEditingController(text: config.apiModel);
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _apiKey.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final config = ref.watch(
      settingsControllerProvider.select((settings) => settings.localization),
    );
    final model = ref.watch(localModelControllerProvider);
    final usage = ref.watch(translationTokenUsageProvider);
    final cacheCount = ref.watch(translationCacheCountProvider);
    final balance = ref.watch(translationBalanceProvider);
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
                controller.setLocalization(config.copyWith(enabled: value)),
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
          const SizedBox(height: CompactTokens.space16),
          Text(
            strings.settingsLocalizationEngine,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: CompactTokens.space8),
          SegmentedButton<TranslationEngineKind>(
            segments: [
              ButtonSegment(
                value: TranslationEngineKind.local,
                label: Text(strings.settingsLocalizationEngineLocal),
                icon: const Icon(Icons.offline_bolt_outlined),
              ),
              ButtonSegment(
                value: TranslationEngineKind.openAiCompatible,
                label: Text(strings.settingsLocalizationEngineApi),
                icon: const Icon(Icons.cloud_outlined),
              ),
            ],
            selected: {config.engine},
            onSelectionChanged: (selection) => controller.setLocalization(
              config.copyWith(engine: selection.first),
            ),
          ),
          const SizedBox(height: CompactTokens.space16),
          if (config.engine == TranslationEngineKind.local)
            _LocalModelBlock(state: model)
          else
            _ApiBlock(
              config: config,
              baseUrl: _baseUrl,
              apiKey: _apiKey,
              model: _model,
              onSave: () => controller.setLocalization(
                config.copyWith(
                  apiBaseUrl: _baseUrl.text.trim(),
                  apiKey: _apiKey.text.trim(),
                  apiModel: _model.text.trim(),
                ),
              ),
              balance: balance.value,
              onCheckBalance: () =>
                  ref.read(translationBalanceRequestProvider.notifier).state++,
            ),
          const SizedBox(height: CompactTokens.space16),
          _Ledger(
            tokens: usage.value?.total,
            cached: cacheCount.value,
            onClear: () async {
              final store = await ref.read(translationStoreProvider.future);
              store.clear();
              ref.invalidate(translationCacheCountProvider);
            },
          ),
          const SizedBox(height: CompactTokens.space12),
          Text(
            strings.settingsLocalizationPrivacy,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalModelBlock extends StatelessWidget {
  final LocalModelState state;

  const _LocalModelBlock({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final status = switch (state.phase) {
      LocalModelPhase.ready => strings.settingsLocalizationLocalReady,
      LocalModelPhase.corrupt => strings.settingsLocalizationLocalCorrupt,
      LocalModelPhase.missing => strings.settingsLocalizationLocalMissing,
      LocalModelPhase.failed =>
        state.message ?? strings.settingsLocalizationLocalMissing,
      LocalModelPhase.checking => strings.settingsLocalizationLocalBundled,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (state.busy)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                state.phase == LocalModelPhase.ready
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                size: 16,
                color: state.phase == LocalModelPhase.ready
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            const SizedBox(width: CompactTokens.space8),
            Expanded(child: Text(status, style: theme.textTheme.bodySmall)),
          ],
        ),
        if (state.phase == LocalModelPhase.ready) ...[
          const SizedBox(height: CompactTokens.space4),
          Text(
            strings.settingsLocalizationLocalBundled,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ApiBlock extends StatelessWidget {
  final LocalizationConfig config;
  final TextEditingController baseUrl;
  final TextEditingController apiKey;
  final TextEditingController model;
  final VoidCallback onSave;
  final TranslationBalance? balance;
  final VoidCallback onCheckBalance;

  const _ApiBlock({
    required this.config,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.onSave,
    required this.balance,
    required this.onCheckBalance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(strings.settingsLocalizationApiBaseUrl, baseUrl),
        const SizedBox(height: CompactTokens.space8),
        _field(strings.settingsLocalizationApiKey, apiKey, obscure: true),
        const SizedBox(height: CompactTokens.space8),
        _field(strings.settingsLocalizationApiModel, model),
        const SizedBox(height: CompactTokens.space8),
        Row(
          children: [
            FilledButton(onPressed: onSave, child: Text(strings.save)),
            const SizedBox(width: CompactTokens.space8),
            TextButton(
              onPressed: config.apiConfigured ? onCheckBalance : null,
              child: Text(strings.settingsLocalizationBalanceCheck),
            ),
          ],
        ),
        const SizedBox(height: CompactTokens.space8),
        Text(
          strings.settingsLocalizationApiHint,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (balance != null) ...[
          const SizedBox(height: CompactTokens.space8),
          Text(
            balance!.supported
                ? '${strings.settingsLocalizationBalance}: '
                      '${balance!.amount ?? '-'} ${balance!.currency ?? ''}'
                : strings.settingsLocalizationBalanceUnsupported,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (balance!.message != null)
            Text(
              balance!.message!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}

class _Ledger extends StatelessWidget {
  final int? tokens;
  final int? cached;
  final Future<void> Function() onClear;

  const _Ledger({
    required this.tokens,
    required this.cached,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.loc;
    return Row(
      children: [
        _LedgerFigure(
          label: strings.settingsLocalizationUsage,
          value: tokens?.toString() ?? '-',
        ),
        const SizedBox(width: CompactTokens.space16),
        _LedgerFigure(
          label: strings.settingsLocalizationCache,
          value: cached?.toString() ?? '-',
        ),
        const Spacer(),
        TextButton(onPressed: onClear, child: Text(strings.clear)),
      ],
    );
  }
}

class _LedgerFigure extends StatelessWidget {
  final String label;
  final String value;

  const _LedgerFigure({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: muted)),
        const SizedBox(width: CompactTokens.space4),
        Text(value, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
