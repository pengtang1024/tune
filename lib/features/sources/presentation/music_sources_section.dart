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
import 'package:tune/features/sources/application/source_health_reports.dart';
import 'package:tune/features/sources/domain/source_health.dart';
import 'package:tune/features/sources/domain/source_order.dart';
import 'package:tune/features/sources/domain/source_weights.dart';
import 'package:tune/features/sources/presentation/source_form_dialog.dart';
import 'package:tune/features/sources/presentation/source_menu_button.dart';
import 'package:tune/shared/ui/compact_spinner.dart';
import 'package:tune/shared/ui/meta_badge.dart';
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
    final health = ref.watch(sourceHealthReportsProvider);
    final groups = _groupSources(sources, sourceService, health);
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
            for (final source in groups.main)
              _SourceTile(
                source: source,
                summary: library.summaries[source.id],
                lastScanAt:
                    library.summaries[source.id]?.scannedAt ??
                    lastScanAt[source.id],
                health: health[source.id]!,
                busy: busy,
                inMore: false,
                canMoveToMain: false,
                previousSourceId: _previousSourceId(groups, source, health),
                nextSourceId: _nextSourceId(groups, source, health),
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
                    lastScanAt:
                        library.summaries[source.id]?.scannedAt ??
                        lastScanAt[source.id],
                    health: health[source.id]!,
                    busy: busy,
                    inMore: true,
                    canMoveToMain: health[source.id]?.healthy ?? false,
                    previousSourceId: _previousSourceId(groups, source, health),
                    nextSourceId: _nextSourceId(groups, source, health),
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
  final List<MusicSourceConfig> main;
  final List<MusicSourceConfig> more;

  const _SourceGroups({required this.main, required this.more});
}

/// Splits the sources of the list into the groups the reader sees.
///
/// The weight says where a source belongs; the local music is always in the
/// main list, and a source below the threshold waits in the folded group.
_SourceGroups _groupSources(
  List<MusicSourceConfig> sources,
  MusicSourceService service,
  Map<String, SourceHealthReport> health,
) {
  final ordered = orderSourcesByBand(sources, health);

  final main = <MusicSourceConfig>[];
  final more = <MusicSourceConfig>[];
  for (final source in ordered) {
    final weight = SourceWeights.of(
      source,
      isFeatured: service.isFeatured(source),
    );
    final healthy = health[source.id]?.healthy ?? false;
    if (source.isLocal || (!SourceWeights.inMore(weight) && healthy)) {
      main.add(source);
    } else {
      more.add(source);
    }
  }

  return _SourceGroups(main: main, more: more);
}

/// The non-local sources of the main group.
List<MusicSourceConfig> _mainSources(_SourceGroups groups) {
  return [
    for (final source in groups.main)
      if (!source.isLocal) source,
  ];
}

/// The sources of the group a source stands in, in display order.
List<MusicSourceConfig> _groupSourcesOf(
  _SourceGroups groups,
  MusicSourceConfig source,
) {
  return groups.main.contains(source) ? _mainSources(groups) : groups.more;
}

/// The source above [source] when a move is allowed.
///
/// The list is ordered by health band first, then by weight. A move can only
/// trade places inside one band; at a band boundary the menu entry is
/// disabled, because swapping two weights would not change the order.
String? _previousSourceId(
  _SourceGroups groups,
  MusicSourceConfig source,
  Map<String, SourceHealthReport> health,
) {
  return _neighbourId(groups, source, health, -1);
}

/// The source below [source] when a move is allowed.
String? _nextSourceId(
  _SourceGroups groups,
  MusicSourceConfig source,
  Map<String, SourceHealthReport> health,
) {
  return _neighbourId(groups, source, health, 1);
}

String? _neighbourId(
  _SourceGroups groups,
  MusicSourceConfig source,
  Map<String, SourceHealthReport> health,
  int delta,
) {
  final list = _groupSourcesOf(groups, source);
  final index = list.indexWhere((item) => item.id == source.id);
  final target = index + delta;
  if (index < 0 || target < 0 || target >= list.length) return null;
  final other = list[target];
  final band = health[source.id]?.band ?? 0;
  if ((health[other.id]?.band ?? 0) != band) return null;
  return other.id;
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
  final SourceHealthReport health;
  final bool busy;
  final bool inMore;
  final bool canMoveToMain;
  final String? previousSourceId;
  final String? nextSourceId;

  const _SourceTile({
    required this.source,
    required this.summary,
    required this.lastScanAt,
    required this.health,
    required this.busy,
    required this.inMore,
    required this.canMoveToMain,
    required this.previousSourceId,
    required this.nextSourceId,
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
                      tooltip:
                          '$status\n'
                          '${context.loc.sourcesHealthScore(health.score)}\n'
                          '${context.loc.sourcesHealthBreakdown(health.availability, health.configuration, health.scan, health.freshness, health.output, health.speed, health.reliability, health.stability, health.playable, health.artwork, health.metadata, health.activity)}',
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
          if (!source.isLocal)
            SourceMenuButton(
              source: source,
              enabled: !busy,
              inMore: inMore,
              canMoveToMain: canMoveToMain,
              previousSourceId: previousSourceId,
              nextSourceId: nextSourceId,
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
          SourceFormDialog.edit(source: source, fields: fields),
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
