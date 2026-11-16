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

  /// The models the vendor reported, as of the last fetch.
  final List<String> models;
  final bool modelsLoading;
  final bool modelsFailed;
  final TranslationBalance? balance;
  final VoidCallback onFetchModels;
  final VoidCallback onSave;
  final VoidCallback onCheckBalance;

  const SettingsLocalizationProviderBlock({
    super.key,
    required this.provider,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.models = const [],
    this.modelsLoading = false,
    this.modelsFailed = false,
    required this.balance,
    required this.onFetchModels,
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

  Future<void> _pickModel() async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => _ModelPickerDialog(
        models: widget.models,
        selected: widget.model.text.trim(),
      ),
    );
    if (chosen == null || !mounted) return;
    widget.model.text = chosen;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final provider = widget.provider;

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
                _showKey
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
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
        const SizedBox(height: CompactTokens.space4),
        Wrap(
          spacing: CompactTokens.space8,
          runSpacing: CompactTokens.space4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: widget.modelsLoading ? null : widget.onFetchModels,
              icon: widget.modelsLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 16),
              label: Text(
                widget.modelsLoading
                    ? strings.settingsLocalizationModelsFetching
                    : strings.settingsLocalizationModelsFetch,
              ),
            ),
            if (widget.models.isNotEmpty) ...[
              Text(
                strings.settingsLocalizationModelsFetched(widget.models.length),
                style: muted,
              ),
              TextButton(
                onPressed: _pickModel,
                child: Text(strings.settingsLocalizationModelsPick),
              ),
            ],
          ],
        ),
        if (widget.modelsFailed) ...[
          const SizedBox(height: CompactTokens.space4),
          Text(strings.settingsLocalizationModelsFailed, style: muted),
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

/// Picks one model out of a list that can hold hundreds of entries.
class _ModelPickerDialog extends StatefulWidget {
  final List<String> models;
  final String selected;

  const _ModelPickerDialog({required this.models, required this.selected});

  @override
  State<_ModelPickerDialog> createState() => _ModelPickerDialogState();
}

class _ModelPickerDialogState extends State<_ModelPickerDialog> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.loc;
    final query = _search.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? widget.models
        : widget.models
              .where((model) => model.toLowerCase().contains(query))
              .toList();

    return AlertDialog(
      title: Text(strings.settingsLocalizationModelsPick),
      content: SizedBox(
        width: 420,
        height: 380,
        child: Column(
          children: [
            TextField(
              controller: _search,
              autofocus: true,
              decoration: InputDecoration(
                hintText: strings.settingsLocalizationModelsSearch,
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: CompactTokens.space8),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Text(
                        strings.settingsLocalizationModelsEmpty,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final model = visible[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            model,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: model == widget.selected
                              ? const Icon(Icons.check, size: 18)
                              : null,
                          onTap: () => Navigator.of(context).pop(model),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
      ],
    );
  }
}
