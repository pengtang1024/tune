import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_runtime_factory.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';

/// Settings section that owns the visible source list.
///
/// It composes three controllers without duplicating their state: source
/// configuration comes from [musicSourcesControllerProvider], scan results
/// come from the library controller, and the startup switch lives in settings.
class MusicSourcesSection extends ConsumerWidget {
  const MusicSourcesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final sourcesAsync = ref.watch(musicSourcesControllerProvider);
    final library = ref.watch(
      libraryControllerProvider.select((value) {
        final state = value.valueOrNull;
        return (
          scanning: state?.isScanning ?? false,
          loading: state?.isLoading ?? false,
          progress: state?.scanProgress ?? 0.0,
          summaries:
              state?.sourceSummaries ?? const <String, SourceScanSummary>{},
        );
      }),
    );
    final settings = ref.watch(settingsControllerProvider);
    final scanning = library.scanning;
    final busy = scanning || library.loading;

    final sources = sourcesAsync.valueOrNull?.sources ?? const [];
    final lastScanAt =
        sourcesAsync.valueOrNull?.lastScanAt ?? const <String, DateTime>{};
    final sourceService = ref.watch(musicSourceServiceProvider);
    final canScan =
        !busy &&
        sources.any(
          (source) => source.enabled && sourceService.supportsConfig(source),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: CompactTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.sourcesTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
          const SizedBox(height: CompactTokens.space8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CompactTokens.space12,
              vertical: CompactTokens.space8,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: CompactTokens.borderRadius8,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.loc.sourcesAutoScan,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.loc.sourcesAutoScanDescription,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: settings.autoScanOnStartup,
                      onChanged: (value) => ref
                          .read(settingsControllerProvider.notifier)
                          .setAutoScanOnStartup(value),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                if (scanning) ...[
                  const SizedBox(height: CompactTokens.space6),
                  LinearProgressIndicator(
                    value: library.progress,
                    minHeight: 2,
                    backgroundColor: theme.colorScheme.outlineVariant,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: CompactTokens.space8),
          if (sourcesAsync.isLoading && !sourcesAsync.hasValue)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: CompactTokens.space8),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else
            for (final source in sources)
              _SourceTile(
                source: source,
                summary: library.summaries[source.id],
                lastScanAt: lastScanAt[source.id],
                busy: busy,
              ),
          const SizedBox(height: CompactTokens.space8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: canScan ? () => _scanAll(context, ref) : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(
                    horizontal: CompactTokens.space8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 11),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                icon: scanning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded, size: 15),
                label: Text(context.loc.sourcesScanAll),
              ),
              if (isMusicPluginRuntimeSupported) ...[
                const SizedBox(width: CompactTokens.space8),
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _importPlugin(context, ref),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: CompactTokens.space8,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 11),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  icon: const Icon(Icons.extension_outlined, size: 15),
                  label: Text(context.loc.sourcesImportPlugin),
                ),
              ],
              const SizedBox(width: CompactTokens.space8),
              Flexible(
                child: Text(
                  context.loc.sourcesScanMayTakeSeconds,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _scanAll(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsControllerProvider);
    await ref
        .read(libraryControllerProvider.notifier)
        .scan(settings.effectiveScanPaths);
    if (!context.mounted) return;

    final state = ref.read(libraryControllerProvider).valueOrNull;
    final message =
        state?.errorMessage ??
        state?.statusMessage ??
        context.loc.sourcesScanCompleted;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  Future<void> _importPlugin(BuildContext context, WidgetRef ref) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.sourcesImportPluginTitle),
        content: Text(context.loc.sourcesImportPluginMessage),

        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('url'),
            child: Text(context.loc.sourcesImportPluginFromUrl),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('file'),
            child: Text(context.loc.chooseFile),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (choice == 'url') {
      await _importPluginFromUrl(context, ref);
      return;
    }
    if (choice != 'file') return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['js'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!context.mounted) return;
    final file = result.files.first;

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showMessage(context, context.loc.sourcesPluginUnreadable);
      return;
    }
    if (bytes.length > 2 * 1024 * 1024) {
      _showMessage(context, context.loc.sourcesPluginTooLarge);
      return;
    }

    final script = utf8.decode(bytes, allowMalformed: true);
    if (!context.mounted) return;

    try {
      final controller = ref.read(musicSourcesControllerProvider.notifier);
      final config = await controller.installPlugin(
        originalName: file.name,
        script: script,
      );
      if (!context.mounted) return;

      final fields = ref.read(musicSourceServiceProvider).fieldsFor(config);
      final saved = await showDialog<bool>(
        context: context,
        builder: (context) =>
            _SourceSettingsDialog(source: config, fields: fields),
      );
      if (saved == true) {
        await controller.setEnabled(config.id, true);
      }
      if (!context.mounted) return;
      _showMessage(
        context,
        saved == true
            ? context.loc.sourcesPluginImportedEnabled(config.name)
            : context.loc.sourcesPluginImported(config.name),
      );
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, context.loc.sourcesPluginImportFailed('$error'));
    }
  }

  /// Downloads a plugin from a link the user typed in.
  Future<void> _importPluginFromUrl(BuildContext context, WidgetRef ref) async {
    final url = await showDialog<String>(
      context: context,
      builder: (context) => const _PluginUrlDialog(),
    );
    if (url == null || url.isEmpty || !context.mounted) return;

    try {
      final controller = ref.read(musicSourcesControllerProvider.notifier);
      final config = await controller.installPluginFromUrl(url);
      if (!context.mounted) return;

      final fields = ref.read(musicSourceServiceProvider).fieldsFor(config);
      final saved = await showDialog<bool>(
        context: context,
        builder: (context) =>
            _SourceSettingsDialog(source: config, fields: fields),
      );
      if (saved == true) {
        await controller.setEnabled(config.id, true);
      }
      if (!context.mounted) return;
      _showMessage(
        context,
        saved == true
            ? context.loc.sourcesPluginImportedEnabled(config.name)
            : context.loc.sourcesPluginImported(config.name),
      );
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, context.loc.sourcesPluginImportFailed('$error'));
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
  }
}

class _SourceTile extends ConsumerWidget {
  final MusicSourceConfig source;
  final SourceScanSummary? summary;
  final DateTime? lastScanAt;
  final bool busy;

  const _SourceTile({
    required this.source,
    required this.summary,
    required this.lastScanAt,
    required this.busy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final sourceService = ref.watch(musicSourceServiceProvider);
    final supported = sourceService.supportsConfig(source);
    final fields = sourceService.fieldsFor(source);
    final configured = sourceService.isConfigured(source);
    final status = _statusText(
      context,
      configured,
      fields,
      supported: supported,
    );
    final statusColor = _statusColor(
      context,
      configured: configured,
      supported: supported,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: CompactTokens.space4),
      padding: const EdgeInsets.symmetric(
        horizontal: CompactTokens.space8,
        vertical: CompactTokens.space4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: CompactTokens.borderRadius6,
      ),
      child: Row(
        children: [
          Icon(_icon(source.kind), size: 16, color: muted),
          const SizedBox(width: CompactTokens.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Tooltip(
                        message: source.description,
                        child: Text(
                          source.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (source.kind != MusicSourceKind.localDirectory) ...[
                      const SizedBox(width: CompactTokens.space4),
                      _KindBadge(kind: source.kind),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Tooltip(
                  message: status,
                  child: Text(
                    status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: statusColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (fields.isNotEmpty && supported)
            if (source.isPlugin)
              SizedBox(
                width: 28,
                height: 28,
                child: PopupMenuButton<String>(
                  tooltip: context.loc.sourcesPluginActions,
                  enabled: !busy,
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert_rounded, size: 15, color: muted),
                  onSelected: (value) {
                    if (value == 'config') {
                      _openSettings(context, source, fields);
                    } else if (value == 'update') {
                      _updatePlugin(context, ref);
                    } else if (value == 'delete') {
                      _confirmRemove(context, ref);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'config',
                      height: 36,
                      child: Text(context.loc.sourcesConfigure),
                    ),
                    if (source.pluginUrl != null)
                      PopupMenuItem(
                        value: 'update',
                        height: 36,
                        child: Text(context.loc.sourcesUpdatePlugin),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      height: 36,
                      child: Text(context.loc.sourcesDeletePlugin),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  key: ValueKey('source-config-${source.id}'),
                  tooltip: context.loc.sourcesConfigure,
                  onPressed: busy
                      ? null
                      : () => _openSettings(context, source, fields),
                  icon: const Icon(Icons.tune_rounded, size: 15),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  style: IconButton.styleFrom(
                    foregroundColor: muted,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
          Switch(
            key: ValueKey('source-switch-${source.id}'),
            value: source.enabled,
            onChanged: busy || !supported
                ? null
                : (value) async {
                    final controller = ref.read(
                      musicSourcesControllerProvider.notifier,
                    );
                    if (!value || configured || fields.isEmpty) {
                      await controller.setEnabled(source.id, value);
                      return;
                    }

                    final saved = await _openSettings(context, source, fields);
                    if (!saved || !context.mounted) return;
                    await controller.setEnabled(source.id, true);
                  },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  String _statusText(
    BuildContext context,
    bool configured,
    List<MusicSourceField> fields, {
    required bool supported,
  }) {
    if (!supported) return context.loc.sourcesUnsupported;
    if (!source.enabled) return context.loc.sourcesDisabled;
    if (!configured) {
      final required = fields.where((field) => field.required);
      final hint = required.isEmpty ? '' : required.first.hint;
      return hint.isEmpty
          ? context.loc.sourcesNeedsConfiguration
          : context.loc.sourcesNeedsConfigurationHint(hint);
    }

    final result = summary;
    if (result == null) {
      if (lastScanAt != null) {
        return context.loc.sourcesLastScan(_formatTime(context, lastScanAt!));
      }
      return source.kind == MusicSourceKind.localDirectory
          ? context.loc.sourcesAutoScanLocal
          : context.loc.sourcesWaitingFirstScan;
    }

    switch (result.status) {
      case SourceScanStatus.success:
        return context.loc.sourcesScannedCount(
          result.songCount,
          _formatTime(context, result.scannedAt),
        );
      case SourceScanStatus.needsConfiguration:
        return result.message ?? context.loc.sourcesNeedsConfiguration;
      case SourceScanStatus.skipped:
        return result.message ?? context.loc.sourcesSkipped;
      case SourceScanStatus.failed:
        return result.message ?? context.loc.sourcesScanFailed;
    }
  }

  Color _statusColor(
    BuildContext context, {
    required bool configured,
    required bool supported,
  }) {
    final theme = Theme.of(context);
    if (!supported) return theme.colorScheme.error;
    if (!source.enabled) return theme.colorScheme.onSurfaceVariant;
    if (!configured) return theme.colorScheme.tertiary;
    if (summary?.status == SourceScanStatus.failed) {
      return theme.colorScheme.error;
    }
    return theme.colorScheme.onSurfaceVariant;
  }

  Future<bool> _openSettings(
    BuildContext context,
    MusicSourceConfig source,
    List<MusicSourceField> fields,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _SourceSettingsDialog(source: source, fields: fields),
    );
    return saved == true;
  }

  /// Fetches the current script of a plugin that was imported by URL.
  Future<void> _updatePlugin(BuildContext context, WidgetRef ref) async {
    final source = this.source;
    try {
      final update = await ref
          .read(musicSourcesControllerProvider.notifier)
          .updatePlugin(source.id);
      if (!context.mounted) return;
      _showMessage(
        context,
        update.changed
            ? context.loc.sourcesPluginUpdated(source.name, update.version)
            : context.loc.sourcesPluginUpToDate(source.name),
      );
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, context.loc.sourcesPluginUpdateFailed('$error'));
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.sourcesDeletePluginTitle),
        content: Text(context.loc.sourcesDeletePluginMessage(source.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.loc.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(musicSourcesControllerProvider.notifier)
        .removePlugin(source.id);
    if (!context.mounted) return;
    await ref.read(libraryControllerProvider.notifier).dropSource(source.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.loc.sourcesDeleted(source.name)),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _KindBadge extends StatelessWidget {
  final MusicSourceKind kind;

  const _KindBadge({required this.kind});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (kind) {
      MusicSourceKind.localDirectory => context.loc.sourceKindLocal,
      MusicSourceKind.openCatalog => context.loc.sourceKindOpenCatalog,
      MusicSourceKind.openApi => context.loc.sourceKindOpenApi,
      MusicSourceKind.plugin => context.loc.sourceKindPlugin,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 9,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Asks for the address of a plugin script.
class _PluginUrlDialog extends StatefulWidget {
  const _PluginUrlDialog();

  @override
  State<_PluginUrlDialog> createState() => _PluginUrlDialogState();
}

class _PluginUrlDialogState extends State<_PluginUrlDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.loc.sourcesPluginUrlTitle),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.loc.sourcesPluginUrlTitle,
            hintText: context.loc.sourcesPluginUrlHint,
            errorText: _error,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.loc.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(context.loc.ok)),
      ],
    );
  }

  void _submit() {
    final url = _controller.text.trim();
    final uri = Uri.tryParse(url);
    if (url.isEmpty ||
        uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      setState(() => _error = context.loc.sourcesPluginUrlInvalid);
      return;
    }
    Navigator.of(context).pop(url);
  }
}

class _SourceSettingsDialog extends ConsumerStatefulWidget {
  final MusicSourceConfig source;
  final List<MusicSourceField> fields;

  const _SourceSettingsDialog({required this.source, required this.fields});

  @override
  ConsumerState<_SourceSettingsDialog> createState() =>
      _SourceSettingsDialogState();
}

class _SourceSettingsDialogState extends ConsumerState<_SourceSettingsDialog> {
  late final Map<String, TextEditingController> _controllers;
  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.fields)
        field.key: TextEditingController(
          text: widget.source.setting(field.key) ?? '',
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.loc.sourcesConfigureTitle(widget.source.name)),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final field in widget.fields) ...[
                if (field.choices.isNotEmpty)
                  _ChoiceField(
                    field: field,
                    value: _choiceValue(field),
                    onChanged: (value) => _selectChoice(field, value),
                  )
                else
                  TextField(
                    controller: _controllers[field.key],
                    obscureText: field.secret,
                    decoration: InputDecoration(
                      labelText: field.label,
                      hintText: field.hint,
                      errorText: _errors[field.key],
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: field.numeric
                        ? const TextInputType.numberWithOptions(decimal: false)
                        : TextInputType.text,
                  ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.loc.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(context.loc.save)),
      ],
    );
  }

  Future<void> _save() async {
    _errors.clear();
    final settings = <String, String>{};

    for (final field in widget.fields) {
      final value = field.choices.isEmpty
          ? (_controllers[field.key]?.text.trim() ?? '')
          : _choiceValue(field);
      if (field.required && value.isEmpty) {
        _errors[field.key] = context.loc.sourcesFieldRequired(field.label);
      }
      if (field.numeric && value.isNotEmpty && int.tryParse(value) == null) {
        _errors[field.key] = context.loc.sourcesFieldNumeric;
      }
      settings[field.key] = value;
    }

    if (_errors.isNotEmpty) {
      setState(() {});
      return;
    }

    await ref
        .read(musicSourcesControllerProvider.notifier)
        .updateSettings(widget.source.id, settings);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  /// The value a setting of a fixed set of choices shows.
  String _choiceValue(MusicSourceField field) {
    final current = _controllers[field.key]?.text ?? '';
    for (final choice in field.choices) {
      if (choice.value == current) return current;
    }
    return field.choices.first.value;
  }

  /// Keeps the value of a choice in the controller of its field.
  void _selectChoice(MusicSourceField field, String value) {
    _controllers[field.key]?.text = value;
    setState(() {});
  }
}

/// A setting that only allows a fixed set of values.
///
/// The source declares the options, so the interface does not have to know
/// which setting of which source it is showing.
class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final MusicSourceField field;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isDense: true,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hint,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final choice in field.choices)
          DropdownMenuItem(value: choice.value, child: Text(choice.label)),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}

IconData _icon(MusicSourceKind kind) {
  return switch (kind) {
    MusicSourceKind.localDirectory => Icons.folder_outlined,
    MusicSourceKind.openCatalog => Icons.public_rounded,
    MusicSourceKind.openApi => Icons.api_rounded,
    MusicSourceKind.plugin => Icons.extension_rounded,
  };
}

/// The time of the last scan, written the way the locale writes it.
///
/// The clock and the day follow the language of the interface, so a reader
/// never has to read a date of another language.
String _formatTime(BuildContext context, DateTime time) {
  final locale = Localizations.localeOf(context).toString();
  final now = DateTime.now();
  final sameDay =
      now.year == time.year && now.month == time.month && now.day == time.day;

  final clock = DateFormat.Hm(locale).format(time);
  if (sameDay) return clock;
  return '${DateFormat.yMd(locale).format(time)} $clock';
}
