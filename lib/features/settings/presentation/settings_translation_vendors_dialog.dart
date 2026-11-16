import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_component_registry.dart';
import 'package:tune/data/services/translation/translation_provider_catalog.dart';
import 'package:tune/domain/models/localization_config.dart';
import 'package:tune/domain/models/translation_provider.dart';
import 'package:tune/features/local_components/application/local_components_controller.dart';
import 'package:tune/features/localization/application/localization_providers.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_localization_local_block.dart';
import 'package:tune/features/settings/presentation/settings_localization_provider_block.dart';
import 'package:tune/features/settings/presentation/settings_translation_vendors_labels.dart';

/// Opens the vendor page: every service the player can translate with, in one
/// searchable place, away from the switch and the ledger on the card.
Future<void> showTranslationVendorsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const SettingsTranslationVendorsDialog(),
  );
}

/// The vendor page.
///
/// The catalog has outgrown a dropdown: readers need to search, the entries
/// split into plans, metered keys, the local model and a free-form endpoint,
/// and a few vendors carry their own behavior (an endpoint that cannot list
/// models, a model list that does not sit under the chat path). The left half
/// is the searchable catalog; the right half configures the chosen vendor.
class SettingsTranslationVendorsDialog extends ConsumerStatefulWidget {
  const SettingsTranslationVendorsDialog({super.key});

  @override
  ConsumerState<SettingsTranslationVendorsDialog> createState() =>
      _SettingsTranslationVendorsDialogState();
}

class _SettingsTranslationVendorsDialogState
    extends ConsumerState<SettingsTranslationVendorsDialog> {
  late final TextEditingController _search;
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _model;
  late String _syncedBackend;

  /// The endpoint the model list was last read from; `null` until asked.
  ProviderModelQuery? _modelQuery;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
    final config = ref.read(settingsControllerProvider).localization;
    _syncedBackend = config.backendId;
    final credential = config.activeCredential;
    _baseUrl = TextEditingController(text: credential.baseUrl);
    _apiKey = TextEditingController(text: credential.apiKey);
    _model = TextEditingController(text: credential.model);
  }

  @override
  void dispose() {
    _search.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    _model.dispose();
    super.dispose();
  }

  void _loadCredential(String backendId, LocalizationConfig config) {
    final credential = config.credentialFor(backendId);
    _baseUrl.text = credential.baseUrl;
    _apiKey.text = credential.apiKey;
    _model.text = credential.model;
    _syncedBackend = backendId;
    _modelQuery = null;
  }

  Future<void> _select(TranslationProvider provider) async {
    final config = ref.read(settingsControllerProvider).localization;
    if (provider.id == config.backendId) return;
    var accepted = config.privacyAccepted;
    if (!provider.isLocalModel && !accepted) {
      accepted = await _confirmPrivacy(provider.name);
      if (!accepted || !mounted) return;
    }
    final next = config.copyWith(
      backendId: provider.id,
      privacyAccepted: accepted,
    );
    ref.read(settingsControllerProvider.notifier).setLocalization(next);
    setState(() => _loadCredential(provider.id, next));
  }

  void _save(TranslationProvider provider) {
    final config = ref.read(settingsControllerProvider).localization;
    ref
        .read(settingsControllerProvider.notifier)
        .setLocalization(
          config.withCredential(
            provider.id,
            ProviderCredential(
              apiKey: _apiKey.text.trim(),
              model: _model.text.trim(),
              baseUrl: _baseUrl.text.trim(),
            ),
          ),
        );
    _refreshModels(provider);
  }

  /// Asks the chosen vendor for the models it currently serves.
  void _refreshModels(TranslationProvider provider) {
    if (provider.isLocalModel || !provider.listsModels) return;
    final query = (
      providerId: provider.id,
      baseUrl: _baseUrl.text.trim(),
      apiKey: _apiKey.text.trim(),
    );
    ref.invalidate(providerModelsProvider(query));
    setState(() => _modelQuery = query);
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

  Future<void> _downloadLocalComponents(LocalComponentSpec model) async {
    final controller = ref.read(localComponentsControllerProvider.notifier);
    final states = ref.read(localComponentsControllerProvider).valueOrNull;
    for (final spec in [LocalComponentRegistry.translationRuntime, model]) {
      final current = states?[spec.id];
      if (current == null || current.usable || current.busy) continue;
      await controller.download(spec.id);
    }
  }

  void _cancelLocalComponents(LocalComponentSpec model) {
    final controller = ref.read(localComponentsControllerProvider.notifier);
    controller.cancel(LocalComponentRegistry.translationRuntime.id);
    controller.cancel(model.id);
  }

  Future<void> _removeLocalComponents(LocalComponentSpec model) async {
    final controller = ref.read(localComponentsControllerProvider.notifier);
    await controller.remove(LocalComponentRegistry.translationRuntime.id);
    await controller.remove(model.id);
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
        if (previous?.backendId != next.backendId &&
            next.backendId != _syncedBackend) {
          setState(() => _loadCredential(next.backendId, next));
        }
      },
    );
    final provider = providerById(config.backendId);

    return Dialog(
      key: const ValueKey('translation-vendors-dialog'),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 840,
        height: 620,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CompactTokens.space16,
                CompactTokens.space12,
                CompactTokens.space8,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.settingsLocalizationVendorsTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: strings.close,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 280, child: _VendorList(
                    search: _search,
                    selectedId: config.backendId,
                    onSelect: (provider) => unawaited(_select(provider)),
                  )),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: provider == null
                        ? Center(
                            child: Text(
                              strings.settingsLocalizationProviderNone,
                              style: theme.textTheme.bodySmall,
                            ),
                          )
                        : _VendorDetail(
                            provider: provider,
                            config: config,
                            baseUrl: _baseUrl,
                            apiKey: _apiKey,
                            model: _model,
                            modelQuery: _modelQuery,
                            onSave: () => _save(provider),
                            onFetchModels: () => _refreshModels(provider),
                            localRuntime: ref.watch(
                              localComponentStateProvider(
                                LocalComponentRegistry.translationRuntime.id,
                              ),
                            ),
                            localModel: ref.watch(
                              localComponentStateProvider(
                                ref.watch(activeTranslationModelProvider).id,
                              ),
                            ),
                            onDownloadLocal: () => unawaited(
                              _downloadLocalComponents(
                                ref.read(activeTranslationModelProvider),
                              ),
                            ),
                            onCancelLocal: () => _cancelLocalComponents(
                              ref.read(activeTranslationModelProvider),
                            ),
                            onRemoveLocal: () => unawaited(
                              _removeLocalComponents(
                                ref.read(activeTranslationModelProvider),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The searchable catalog: plans, metered keys, the local model, custom.
class _VendorList extends StatefulWidget {
  final TextEditingController search;
  final String selectedId;
  final ValueChanged<TranslationProvider> onSelect;

  const _VendorList({
    required this.search,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  State<_VendorList> createState() => _VendorListState();
}

class _VendorListState extends State<_VendorList> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final query = widget.search.text.trim().toLowerCase();
    final header = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    String groupLabel(TranslationProviderKind kind) => switch (kind) {
      TranslationProviderKind.subscription =>
        strings.settingsLocalizationVendorsGroupSubscription,
      TranslationProviderKind.api =>
        strings.settingsLocalizationVendorsGroupApi,
      TranslationProviderKind.local =>
        strings.settingsLocalizationVendorsGroupLocal,
      TranslationProviderKind.custom =>
        strings.settingsLocalizationVendorsGroupCustom,
    };

    String kindLabel(TranslationProviderKind kind) => switch (kind) {
      TranslationProviderKind.subscription =>
        strings.settingsLocalizationVendorsKindSubscription,
      TranslationProviderKind.api => strings.settingsLocalizationVendorsGroupApi,
      TranslationProviderKind.local =>
        strings.settingsLocalizationVendorsGroupLocal,
      TranslationProviderKind.custom =>
        strings.settingsLocalizationVendorsGroupCustom,
    };

    final rows = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(
          CompactTokens.space12,
          CompactTokens.space12,
          CompactTokens.space12,
          CompactTokens.space8,
        ),
        child: TextField(
          key: const ValueKey('translation-vendors-search'),
          controller: widget.search,
          decoration: InputDecoration(
            hintText: strings.settingsLocalizationVendorsSearch,
            isDense: true,
            prefixIcon: const Icon(Icons.search, size: 18),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    ];

    for (final kind in TranslationProviderKind.values) {
      final visible = translationProviderCatalog
          .where((provider) => provider.kind == kind)
          .where(
            (provider) =>
                query.isEmpty ||
                provider.name.toLowerCase().contains(query) ||
                provider.id.toLowerCase().contains(query),
          )
          .toList();
      if (visible.isEmpty) continue;
      rows.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CompactTokens.space16,
            CompactTokens.space8,
            CompactTokens.space16,
            CompactTokens.space4,
          ),
          child: Text(
            groupLabel(kind),
            key: ValueKey('translation-vendors-group-${kind.name}'),
            style: header,
          ),
        ),
      );
      for (final provider in visible) {
        rows.add(
          ListTile(
            key: ValueKey('translation-vendor-${provider.id}'),
            dense: true,
            selected: provider.id == widget.selectedId,
            title: Text(
              translationVendorName(strings, provider),
              maxLines: 1,
            ),
            subtitle: Text(
              kindLabel(kind),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: provider.id == widget.selectedId
                ? const Icon(Icons.check, size: 18)
                : null,
            onTap: () => widget.onSelect(provider),
          ),
        );
      }
    }

    if (rows.length == 1) {
      rows.add(
        Padding(
          padding: const EdgeInsets.all(CompactTokens.space16),
          child: Text(
            strings.settingsLocalizationVendorsEmpty,
            style: theme.textTheme.bodySmall,
          ),
        ),
      );
    }

    return ListView(children: rows);
  }
}

/// The right half: what the chosen vendor needs, and its own quirks.
class _VendorDetail extends ConsumerWidget {
  final TranslationProvider provider;
  final LocalizationConfig config;
  final TextEditingController baseUrl;
  final TextEditingController apiKey;
  final TextEditingController model;
  final ProviderModelQuery? modelQuery;
  final VoidCallback onSave;
  final VoidCallback onFetchModels;
  final LocalComponentState localRuntime;
  final LocalComponentState localModel;
  final VoidCallback onDownloadLocal;
  final VoidCallback onCancelLocal;
  final VoidCallback onRemoveLocal;

  const _VendorDetail({
    required this.provider,
    required this.config,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.modelQuery,
    required this.onSave,
    required this.onFetchModels,
    required this.localRuntime,
    required this.localModel,
    required this.onDownloadLocal,
    required this.onCancelLocal,
    required this.onRemoveLocal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final models = modelQuery == null
        ? null
        : ref.watch(providerModelsProvider(modelQuery!));
    final balance = provider.supportsBalance
        ? ref.watch(translationBalanceProvider)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(CompactTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translationVendorName(strings, provider),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (provider.subscription) ...[
            const SizedBox(height: CompactTokens.space4),
            Text(strings.settingsLocalizationSubscriptionHint, style: muted),
          ],
          const SizedBox(height: CompactTokens.space12),
          if (provider.isLocalModel)
            SettingsLocalizationLocalBlock(
              runtime: localRuntime,
              model: localModel,
              onDownload: onDownloadLocal,
              onCancel: onCancelLocal,
              onRemove: onRemoveLocal,
            )
          else
            SettingsLocalizationProviderBlock(
              provider: provider,
              baseUrl: baseUrl,
              apiKey: apiKey,
              model: model,
              models: models?.valueOrNull ?? const <String>[],
              modelsLoading: models?.isLoading ?? false,
              modelsFailed: models?.hasError ?? false,
              balance: balance?.value,
              onFetchModels: onFetchModels,
              onSave: onSave,
              onCheckBalance: () =>
                  ref.read(translationBalanceRequestProvider.notifier).state++,
            ),
        ],
      ),
    );
  }
}
