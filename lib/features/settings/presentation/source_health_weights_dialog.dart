import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/source_health_weights.dart';

/// The dialog that adjusts how much each dimension contributes.
class SourceHealthWeightsDialog extends StatefulWidget {
  final SourceHealthWeights initial;

  const SourceHealthWeightsDialog({super.key, required this.initial});

  @override
  State<SourceHealthWeightsDialog> createState() =>
      _SourceHealthWeightsDialogState();
}

class _SourceHealthWeightsDialogState extends State<SourceHealthWeightsDialog> {
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

    return AlertDialog(
      scrollable: true,
      title: Text(context.loc.sourcesHealthWeightsTitle),
      content: SizedBox(
        width: 420,
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc.sourcesHealthWeightsHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: CompactTokens.space8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final row in _rows(context))
                      _weightRow(context, row.$1, row.$2, row.$3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: CompactTokens.space6),
            Text(
              context.loc.sourcesHealthWeightsTotal(total),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              setState(() => _weights = SourceHealthWeights.defaults),
          child: Text(context.loc.sourcesHealthWeightsReset),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.loc.cancel),
        ),
        FilledButton(
          onPressed: total > 0
              ? () => Navigator.of(context).pop(_weights)
              : null,
          child: Text(context.loc.save),
        ),
      ],
    );
  }

  /// The twelve dimensions with the update that belongs to each one.
  List<(String, int, ValueChanged<int>)> _rows(BuildContext context) {
    final loc = context.loc;
    return [
      (
        loc.sourcesHealthAvailability,
        _weights.availability,
        (value) => _set((w) => w.copyWith(availability: value)),
      ),
      (
        loc.sourcesHealthConfiguration,
        _weights.configuration,
        (value) => _set((w) => w.copyWith(configuration: value)),
      ),
      (
        loc.sourcesHealthScan,
        _weights.scan,
        (value) => _set((w) => w.copyWith(scan: value)),
      ),
      (
        loc.sourcesHealthFreshness,
        _weights.freshness,
        (value) => _set((w) => w.copyWith(freshness: value)),
      ),
      (
        loc.sourcesHealthOutput,
        _weights.output,
        (value) => _set((w) => w.copyWith(output: value)),
      ),
      (
        loc.sourcesHealthSpeed,
        _weights.speed,
        (value) => _set((w) => w.copyWith(speed: value)),
      ),
      (
        loc.sourcesHealthReliability,
        _weights.reliability,
        (value) => _set((w) => w.copyWith(reliability: value)),
      ),
      (
        loc.sourcesHealthStability,
        _weights.stability,
        (value) => _set((w) => w.copyWith(stability: value)),
      ),
      (
        loc.sourcesHealthPlayable,
        _weights.playable,
        (value) => _set((w) => w.copyWith(playable: value)),
      ),
      (
        loc.sourcesHealthArtwork,
        _weights.artwork,
        (value) => _set((w) => w.copyWith(artwork: value)),
      ),
      (
        loc.sourcesHealthMetadata,
        _weights.metadata,
        (value) => _set((w) => w.copyWith(metadata: value)),
      ),
      (
        loc.sourcesHealthActivity,
        _weights.activity,
        (value) => _set((w) => w.copyWith(activity: value)),
      ),
    ];
  }

  void _set(SourceHealthWeights Function(SourceHealthWeights) change) {
    setState(() => _weights = change(_weights));
  }

  Widget _weightRow(
    BuildContext context,
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            label: '$value',
            onChanged: (next) => onChanged(next.round()),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.end,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
