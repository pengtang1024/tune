import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/source_health_weights.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// Opens the health-weight editor at the right edge.
Future<SourceHealthWeights?> showSourceHealthWeightsSheet(
  BuildContext context, {
  required SourceHealthWeights initial,
}) {
  final width = MediaQuery.sizeOf(context).width;
  return showDialog<SourceHealthWeights>(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      alignment: Alignment.centerRight,
      insetPadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: math.min(640, width),
        height: MediaQuery.sizeOf(context).height,
        child: Material(child: SourceHealthWeightsSheet(initial: initial)),
      ),
    ),
  );
}

/// The weights as four groups of three rows: a stepper per dimension and
/// the normalized share next to it. The absolute number is a weight, not a
/// percentage; the share is what the reader actually feels.
class SourceHealthWeightsSheet extends StatefulWidget {
  final SourceHealthWeights initial;

  const SourceHealthWeightsSheet({super.key, required this.initial});

  @override
  State<SourceHealthWeightsSheet> createState() =>
      _SourceHealthWeightsSheetState();
}

class _SourceHealthWeightsSheetState extends State<SourceHealthWeightsSheet> {
  late SourceHealthWeights _weights;

  @override
  void initState() {
    super.initState();
    _weights = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _weights.total;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CompactTokens.space16,
              CompactTokens.space12,
              CompactTokens.space8,
              CompactTokens.space8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.loc.sourcesHealthWeightsTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TuneTooltip(
                  message: context.loc.cancel,
                  child: IconButton(
                    key: const ValueKey('source-health-sheet-close'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CompactTokens.space16,
              CompactTokens.space12,
              CompactTokens.space16,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: CompactTokens.space6,
                  runSpacing: CompactTokens.space6,
                  children: [
                    for (final preset in SourceHealthWeights.presets)
                      ChoiceChip(
                        label: Text(_presetLabel(context, preset)),
                        selected: _weights == preset,
                        onSelected: (_) => setState(() => _weights = preset),
                      ),
                  ],
                ),
                const SizedBox(height: CompactTokens.space8),
                Text(
                  context.loc.sourcesHealthWeightsOffHint,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                CompactTokens.space16,
                CompactTokens.space8,
                CompactTokens.space16,
                CompactTokens.space8,
              ),
              children: [
                _group(context, context.loc.sourcesHealthGroupCore, [
                  _row(
                    context,
                    context.loc.sourcesHealthAvailability,
                    _weights.availability,
                    (v) => _weights = _weights.copyWith(availability: v),
                  ),
                  _row(
                    context,
                    context.loc.sourcesHealthConfiguration,
                    _weights.configuration,
                    (v) => _weights = _weights.copyWith(configuration: v),
                  ),
                  _row(
                    context,
                    context.loc.sourcesHealthScan,
                    _weights.scan,
                    (v) => _weights = _weights.copyWith(scan: v),
                  ),
                ], total),
                _group(context, context.loc.sourcesHealthGroupOutput, [
                  _row(
                    context,
                    context.loc.sourcesHealthFreshness,
                    _weights.freshness,
                    (v) => _weights = _weights.copyWith(freshness: v),
                  ),
                  _row(
                    context,
                    context.loc.sourcesHealthOutput,
                    _weights.output,
                    (v) => _weights = _weights.copyWith(output: v),
                  ),
                  _row(
                    context,
                    context.loc.sourcesHealthSpeed,
                    _weights.speed,
                    (v) => _weights = _weights.copyWith(speed: v),
                  ),
                ], total),
                _group(context, context.loc.sourcesHealthGroupReliable, [
                  _row(
                    context,
                    context.loc.sourcesHealthReliability,
                    _weights.reliability,
                    (v) => _weights = _weights.copyWith(reliability: v),
                  ),
                  _row(
                    context,
                    context.loc.sourcesHealthStability,
                    _weights.stability,
                    (v) => _weights = _weights.copyWith(stability: v),
                  ),
                  _row(
                    context,
                    context.loc.sourcesHealthPlayable,
                    _weights.playable,
                    (v) => _weights = _weights.copyWith(playable: v),
                  ),
                ], total),
                _group(context, context.loc.sourcesHealthGroupShow, [
                  _row(
                    context,
                    context.loc.sourcesHealthArtwork,
                    _weights.artwork,
                    (v) => _weights = _weights.copyWith(artwork: v),
                  ),
                  _row(
                    context,
                    context.loc.sourcesHealthMetadata,
                    _weights.metadata,
                    (v) => _weights = _weights.copyWith(metadata: v),
                  ),
                  _row(
                    context,
                    context.loc.sourcesHealthActivity,
                    _weights.activity,
                    (v) => _weights = _weights.copyWith(activity: v),
                  ),
                ], total),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CompactTokens.space16,
              CompactTokens.space8,
              CompactTokens.space12,
              CompactTokens.space8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.loc.sourcesHealthWeightsTotal(total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CompactTypography.mono(
                      theme.colorScheme.onSurfaceVariant,
                      size: CompactTypeScale.mark,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _weights = SourceHealthWeights.defaults),
                  child: Text(context.loc.sourcesHealthWeightsReset),
                ),
                const SizedBox(width: CompactTokens.space8),
                FilledButton(
                  onPressed: total > 0
                      ? () => Navigator.of(context).pop(_weights)
                      : null,
                  child: Text(context.loc.sourcesHealthWeightsDone),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(
    BuildContext context,
    String title,
    List<Widget> rows,
    int total,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CompactTokens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: CompactTokens.space4),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) {
    final theme = Theme.of(context);
    final total = _weights.total;
    final share = total == 0 ? 0 : (value * 100 / total).round();
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          _step(
            context,
            icon: Icons.remove_rounded,
            onPressed: value > 0 ? () => _set(onChanged, value - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: CompactTypography.mono(
                theme.colorScheme.onSurface,
                size: CompactTypeScale.mark,
              ),
            ),
          ),
          _step(
            context,
            icon: Icons.add_rounded,
            onPressed: value < 20 ? () => _set(onChanged, value + 1) : null,
          ),
          SizedBox(
            width: 48,
            child: Text(
              '$share%',
              textAlign: TextAlign.end,
              style: CompactTypography.mono(
                theme.colorScheme.onSurfaceVariant,
                size: CompactTypeScale.mark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _set(ValueChanged<int> onChanged, int value) {
    setState(() => onChanged(value));
  }

  Widget _step(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: CompactTokens.icon16),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      visualDensity: VisualDensity.compact,
    );
  }

  static String _presetLabel(BuildContext context, SourceHealthWeights preset) {
    if (preset == SourceHealthWeights.balanced) {
      return context.loc.sourcesHealthPresetBalanced;
    }
    if (preset == SourceHealthWeights.playableFirst) {
      return context.loc.sourcesHealthPresetPlayable;
    }
    return context.loc.sourcesHealthPresetFresh;
  }
}
