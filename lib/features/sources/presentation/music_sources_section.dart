import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/core/l10n/source_kind_label.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/shared/ui/compact_spinner.dart';
import 'package:tune/shared/ui/meta_chip.dart';
import 'package:tune/shared/ui/source_mark.dart';
import 'package:tune/shared/ui/track_fact.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

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

    final sources = localizedSources(
      context.loc,
      sourcesAsync.valueOrNull?.sources ?? const <MusicSourceConfig>[],
    );
    final lastScanAt =
        sourcesAsync.valueOrNull?.lastScanAt ?? const <String, DateTime>{};
    final sourceService = ref.watch(musicSourceServiceProvider);
    final groups = _groupSources(sources, sourceService);
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
          // The page heading already names the section, so the list below it
          // does not repeat the name.
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
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.loc.sourcesAutoScanDescription,
                            style: theme.textTheme.labelSmall?.copyWith(
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
          else ...[
            for (final source in groups.featured)
              _SourceTile(
                source: source,
                summary: library.summaries[source.id],
                lastScanAt: lastScanAt[source.id],
                busy: busy,
              ),
            if (groups.more.isNotEmpty) ...[
              const SizedBox(height: CompactTokens.space6),
              _GroupHeader(
                title: context.loc.sourcesGroupMore,
                expanded: settings.sourcesMoreExpanded,
                onTap: () => ref
                    .read(settingsControllerProvider.notifier)
                    .setSourcesMoreExpanded(!settings.sourcesMoreExpanded),
              ),
              if (settings.sourcesMoreExpanded)
                for (final source in groups.more)
                  _SourceTile(
                    source: source,
                    summary: library.summaries[source.id],
                    lastScanAt: lastScanAt[source.id],
                    busy: busy,
                  ),
            ],
            if (groups.added.isNotEmpty) ...[
              const SizedBox(height: CompactTokens.space6),
              _GroupHeader(title: context.loc.sourcesGroupAdded),
              for (final source in groups.added)
                _SourceTile(
                  source: source,
                  summary: library.summaries[source.id],
                  lastScanAt: lastScanAt[source.id],
                  busy: busy,
                ),
            ],
          ],
          const SizedBox(height: CompactTokens.space8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: canScan ? () => _scanAll(context, ref) : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, CompactTokens.controlCompact),
                  padding: const EdgeInsets.symmetric(
                    horizontal: CompactTokens.space8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                icon: scanning
                    ? const CompactSpinner.small()
                    : const Icon(
                        Icons.sync_rounded,
                        size: CompactTokens.icon16,
                      ),
                label: Text(context.loc.libraryScanAllSources),
              ),
              const SizedBox(width: CompactTokens.space8),
              Flexible(
                child: Text(
                  context.loc.sourcesScanMayTakeSeconds,
                  style: theme.textTheme.labelSmall?.copyWith(color: muted),
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
}

/// The sources of the list, split into the groups the reader sees.
///
/// The sources that work right away stand at the top, the ones that need a
/// key wait in a folded group, and the ones the reader added are theirs.
class _SourceGroups {
  final List<MusicSourceConfig> featured;
  final List<MusicSourceConfig> more;
  final List<MusicSourceConfig> added;

  const _SourceGroups({
    required this.featured,
    required this.more,
    required this.added,
  });
}

/// Splits the sources of the list into the groups the reader sees.
///
/// Which group a source belongs to is said by the type, not by its id, so a
/// new type lands in the right place without the interface knowing it.
_SourceGroups _groupSources(
  List<MusicSourceConfig> sources,
  MusicSourceService service,
) {
  final featured = <MusicSourceConfig>[];
  final more = <MusicSourceConfig>[];
  final added = <MusicSourceConfig>[];

  for (final source in sources) {
    if (!source.builtIn) {
      added.add(source);
    } else if (service.isFeatured(source)) {
      featured.add(source);
    } else {
      more.add(source);
    }
  }

  return _SourceGroups(featured: featured, more: more, added: added);
}

/// The name of a group of sources.
///
/// A group that can be folded says so with a chevron, so the reader knows
/// there is more under the name.
class _GroupHeader extends StatelessWidget {
  final String title;
  final bool? expanded;
  final VoidCallback? onTap;

  const _GroupHeader({required this.title, this.expanded, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        top: CompactTokens.space4,
        bottom: CompactTokens.space6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: CompactTypography.sans(
                theme.colorScheme.onSurfaceVariant,
                size: CompactTypeScale.label,
                weight: FontWeight.w600,
              ),
            ),
          ),
          if (onTap != null)
            InkWell(
              key: const ValueKey('sources-more-toggle'),
              onTap: onTap,
              borderRadius: CompactTokens.borderRadius6,
              child: Padding(
                padding: const EdgeInsets.all(CompactTokens.space4),
                child: Icon(
                  expanded == true
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: CompactTokens.icon18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
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
    final mark = _statusMark(
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
          // The icon says which source it is, the colour says what kind of
          // source it is: the name of the source is written next to it.
          TuneTooltip(
            message: source.kind.label(context.loc),
            child: Icon(
              sourceIconOf(source.sourceType, source.kind),
              size: CompactTokens.icon16,
              color: factToneColor(
                sourceToneOf(source.kind),
                theme.colorScheme,
              ),
            ),
          ),
          const SizedBox(width: CompactTokens.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: TuneTooltip(
                        message: source.description,
                        child: Text(
                          source.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MetaBadge(
                      icon: mark.icon,
                      tooltip: status,
                      tone: mark.tone,
                      size: CompactTokens.icon14,
                    ),
                    if (summary != null)
                      MetaBadge(
                        icon: Icons.library_music_rounded,
                        tooltip:
                            '${context.loc.sourceStatusTracks} · ${summary!.songCount}',
                      ),
                    if (lastScanAt != null)
                      MetaBadge(
                        icon: Icons.schedule_rounded,
                        tooltip:
                            '${context.loc.sourceStatusLastScan} · ${_formatTime(context, lastScanAt!)}',
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (fields.isNotEmpty && supported)
            SizedBox(
                width: 28,
                height: 28,
                child: TuneTooltip(
                  message: context.loc.sourcesConfigure,
                  child: IconButton(
                    key: ValueKey('source-config-${source.id}'),
                    onPressed: busy
                        ? null
                        : () => _openSettings(context, source, fields),
                    icon: const Icon(
                      Icons.tune_rounded,
                      size: CompactTokens.icon16,
                    ),
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

  /// The state of the source, as the tile shows it.
  _SourceMark _statusMark(
    BuildContext context, {
    required bool configured,
    required bool supported,
  }) {
    if (!supported) {
      return _SourceMark(
        icon: Icons.block_rounded,
        label: context.loc.sourceStatusUnsupported,
        tone: FactTone.error,
      );
    }
    if (!source.enabled) {
      return _SourceMark(
        icon: Icons.toggle_off_rounded,
        label: context.loc.sourceStatusOff,
        tone: FactTone.neutral,
      );
    }
    if (!configured) {
      return _SourceMark(
        icon: Icons.tune_rounded,
        label: context.loc.sourceStatusNeedsSetup,
        tone: FactTone.tertiary,
      );
    }

    return switch (summary?.status) {
      SourceScanStatus.success => _SourceMark(
        icon: Icons.check_circle_outline_rounded,
        label: context.loc.sourceStatusScanned,
        tone: FactTone.secondary,
      ),
      SourceScanStatus.needsConfiguration => _SourceMark(
        icon: Icons.tune_rounded,
        label: context.loc.sourceStatusNeedsSetup,
        tone: FactTone.tertiary,
      ),
      SourceScanStatus.skipped => _SourceMark(
        icon: Icons.skip_next_rounded,
        label: context.loc.sourceStatusSkipped,
        tone: FactTone.neutral,
      ),
      SourceScanStatus.failed => _SourceMark(
        icon: Icons.error_outline_rounded,
        label: context.loc.sourceStatusFailed,
        tone: FactTone.error,
      ),
      null => _SourceMark(
        icon: Icons.hourglass_empty_rounded,
        label: context.loc.sourceStatusWaiting,
        tone: FactTone.neutral,
      ),
    };
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

}

/// The state of a source, drawn as a chip.
class _SourceMark {
  final IconData icon;
  final String label;
  final FactTone tone;

  const _SourceMark({
    required this.icon,
    required this.label,
    required this.tone,
  });
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

/// The time of the last scan, written the way the locale writes it.
///
/// The clock and the day follow the language of the interface, so a reader
/// never has to read a date of another language. The clock also follows the
/// way the language counts the hours, so an English reader sees "9:05 PM"
/// where a German reader sees "21:05".
String _formatTime(BuildContext context, DateTime time) {
  final locale = Localizations.localeOf(context).toString();
  final now = DateTime.now();
  final sameDay =
      now.year == time.year && now.month == time.month && now.day == time.day;

  final clock = DateFormat.jm(locale).format(time);
  if (sameDay) return clock;
  return '${DateFormat.yMMMd(locale).format(time)} $clock';
}
