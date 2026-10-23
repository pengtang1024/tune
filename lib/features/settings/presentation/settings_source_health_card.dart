import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/source_health_weights.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_card_shell.dart';
import 'package:tune/features/settings/presentation/source_health_weights_dialog.dart';

/// Settings card for the weights of the source health dimensions.
///
/// The weights are shown as two short columns instead of one long list: the
/// card sits below the playback settings, and ten stacked rows would push the
/// desktop and about cards far down the page.
class SettingsSourceHealthCard extends ConsumerWidget {
  const SettingsSourceHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weights = ref.watch(
      settingsControllerProvider.select((state) => state.sourceHealthWeights),
    );
    final theme = Theme.of(context);

    return SettingsCard(
      index: '04',
      eyebrow: context.loc.sourcesTitle,
      title: context.loc.sourcesHealthWeightsTitle,
      description: context.loc.settingsSourceHealthDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WeightTable(weights: weights),
          const SizedBox(height: CompactTokens.space12),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.loc.sourcesHealthWeightsTotal(weights.total),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CompactTypography.mono(
                    theme.colorScheme.onSurfaceVariant,
                    size: CompactTypeScale.mark,
                  ),
                ),
              ),
              const SizedBox(width: CompactTokens.space12),
              OutlinedButton.icon(
                key: const ValueKey('settings-source-health-adjust'),
                onPressed: () => _open(context, ref, weights),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, CompactTokens.controlDefault),
                  padding: const EdgeInsets.symmetric(
                    horizontal: CompactTokens.space12,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                icon: const Icon(
                  Icons.tune_rounded,
                  size: CompactTokens.icon16,
                ),
                label: Text(context.loc.settingsAdjustSourceHealthWeights),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    SourceHealthWeights current,
  ) async {
    final result = await showDialog<SourceHealthWeights>(
      context: context,
      builder: (context) => SourceHealthWeightsDialog(initial: current),
    );
    if (result == null) return;
    await ref
        .read(settingsControllerProvider.notifier)
        .setSourceHealthWeights(result);
  }
}

/// The ten dimensions as two aligned columns of label and value.
class _WeightTable extends StatelessWidget {
  final SourceHealthWeights weights;

  const _WeightTable({required this.weights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = <(String, int)>[
      (context.loc.sourcesHealthAvailability, weights.availability),
      (context.loc.sourcesHealthConfiguration, weights.configuration),
      (context.loc.sourcesHealthScan, weights.scan),
      (context.loc.sourcesHealthFreshness, weights.freshness),
      (context.loc.sourcesHealthOutput, weights.output),
      (context.loc.sourcesHealthSpeed, weights.speed),
      (context.loc.sourcesHealthReliability, weights.reliability),
      (context.loc.sourcesHealthStability, weights.stability),
      (context.loc.sourcesHealthCoverage, weights.coverage),
      (context.loc.sourcesHealthActivity, weights.activity),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: CompactTokens.space12,
        vertical: CompactTokens.space10,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(CompactTokens.radius10),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _WeightColumn(entries: entries.sublist(0, 5))),
            VerticalDivider(
              width: CompactTokens.space20,
              thickness: 1,
              color: theme.colorScheme.outlineVariant,
            ),
            Expanded(child: _WeightColumn(entries: entries.sublist(5))),
          ],
        ),
      ),
    );
  }
}

class _WeightColumn extends StatelessWidget {
  final List<(String, int)> entries;

  const _WeightColumn({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: CompactTokens.space8),
                Text(
                  '${entry.$2}',
                  style: CompactTypography.mono(
                    theme.colorScheme.onSurface,
                    size: CompactTypeScale.mark,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
