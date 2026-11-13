import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/translation/translation_balance.dart';
import 'package:tune/domain/models/translation_provider.dart';

/// The key, model and balance of one vendor.
class SettingsLocalizationProviderBlock extends StatefulWidget {
  final TranslationProvider provider;
  final TextEditingController baseUrl;
  final TextEditingController apiKey;
  final TextEditingController model;

  /// Models the running server reports, such as the ones Ollama has pulled.
  final List<String> extraModels;
  final TranslationBalance? balance;
  final VoidCallback onSave;
  final VoidCallback onCheckBalance;

  const SettingsLocalizationProviderBlock({
    super.key,
    required this.provider,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.extraModels = const [],
    required this.balance,
    required this.onSave,
    required this.onCheckBalance,
  });

  @override
  State<SettingsLocalizationProviderBlock> createState() =>
      _SettingsLocalizationProviderBlockState();
}

class _SettingsLocalizationProviderBlockState
    extends State<SettingsLocalizationProviderBlock> {
  bool _showKey = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final provider = widget.provider;
    final suggestions = <String>{
      ...provider.suggestedModels,
      ...widget.extraModels,
    }.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider.isCustom) ...[
          TextField(
            controller: widget.baseUrl,
            decoration: InputDecoration(
              labelText: strings.settingsLocalizationApiBaseUrl,
              isDense: true,
            ),
          ),
          const SizedBox(height: CompactTokens.space8),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: CompactTokens.space8),
            child: Text(
              '${strings.settingsLocalizationApiBaseUrl}: '
              '${provider.baseUrl}',
              style: muted,
            ),
          ),
        TextField(
          controller: widget.apiKey,
          obscureText: !_showKey,
          decoration: InputDecoration(
            labelText: strings.settingsLocalizationApiKey,
            isDense: true,
            suffixIcon: IconButton(
              icon: Icon(
                _showKey ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
              ),
              onPressed: () => setState(() => _showKey = !_showKey),
            ),
          ),
        ),
        if (!provider.allowsEmptyKey) ...[
          const SizedBox(height: CompactTokens.space4),
          Text(strings.settingsLocalizationKeyHint, style: muted),
        ],
        const SizedBox(height: CompactTokens.space8),
        TextField(
          controller: widget.model,
          decoration: InputDecoration(
            labelText: strings.settingsLocalizationApiModel,
            isDense: true,
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: CompactTokens.space8),
          Text(strings.settingsLocalizationModelSuggestions, style: muted),
          const SizedBox(height: CompactTokens.space4),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.model,
            builder: (context, value, _) {
              final current = value.text.trim();
              return Wrap(
                spacing: CompactTokens.space8,
                runSpacing: CompactTokens.space4,
                children: [
                  for (final model in suggestions)
                    ChoiceChip(
                      label: Text(model),
                      selected: current == model,
                      onSelected: (_) => widget.model.text = model,
                    ),
                ],
              );
            },
          ),
        ],
        const SizedBox(height: CompactTokens.space8),
        Row(
          children: [
            FilledButton(onPressed: widget.onSave, child: Text(strings.save)),
            const SizedBox(width: CompactTokens.space8),
            TextButton(
              onPressed: provider.supportsBalance
                  ? widget.onCheckBalance
                  : null,
              child: Text(strings.settingsLocalizationBalanceCheck),
            ),
          ],
        ),
        const SizedBox(height: CompactTokens.space8),
        Text(strings.settingsLocalizationApiHint, style: muted),
        if (!provider.supportsBalance) ...[
          const SizedBox(height: CompactTokens.space4),
          Text(strings.settingsLocalizationBalanceUnsupported, style: muted),
        ],
        if (widget.balance != null) ...[
          const SizedBox(height: CompactTokens.space4),
          Text(
            widget.balance!.supported
                ? '${strings.settingsLocalizationBalance}: '
                      '${widget.balance!.amount ?? '-'} '
                      '${widget.balance!.currency ?? ''}'
                : strings.settingsLocalizationBalanceUnsupported,
            style: muted,
          ),
          if (widget.balance!.message != null)
            Text(widget.balance!.message!, style: muted),
        ],
      ],
    );
  }
}
