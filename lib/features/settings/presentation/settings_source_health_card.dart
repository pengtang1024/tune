import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/source_health_weights.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_card_shell.dart';
import 'package:tune/features/settings/presentation/source_health_weights_sheet.dart';

/// Settings card for the weights of the source health dimensions.
///
/// The reader sees the normalized share of each dimension, not the raw
/// weight: a weight of 15 only means something next to the other eleven.
/// Three presets cover the common philosophies; the custom sheet has the
/// twelve steppers for the reader who wants them.
class SettingsSourceHealthCard extends ConsumerWidget {
  const SettingsSourceHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weights = ref.watch(
      settingsControllerProvider.select((state) => state.sourceHealthWeights),
    );
    final theme = Theme.of(context);

    return SettingsCard(
      index: '05',
      eyebrow: context.loc.sourcesTitle,
      title: context.loc.sourcesHealthWeightsTitle,
      description: context.loc.settingsSourceHealthDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: CompactTokens.space6,
            runSpacing: CompactTokens.space6,
            children: [
              for (final preset in SourceHealthWeights.presets)
                ChoiceChip(
                  key: ValueKey('settings-health-preset-${_presetId(preset)}'),
                  label: Text(_presetLabel(context, preset)),
                  selected: weights == preset,
                  onSelected: (_) => _apply(ref, preset),
                ),
            ],
          ),
          const SizedBox(height: CompactTokens.space12),
          _ShareTable(weights: weights),
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
                label: Text(context.loc.sourcesHealthWeightsCustom),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> _apply(
    WidgetRef ref,
    SourceHealthWeights weights,
  ) async {
    await ref
        .read(settingsControllerProvider.notifier)
        .setSourceHealthWeights(weights);
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    SourceHealthWeights current,
  ) async {
    final result = await showSourceHealthWeightsSheet(
      context,
      initial: current,
    );
    if (result == null) return;
    await _apply(ref, result);
  }

  static String _presetId(SourceHealthWeights preset) {
    if (preset == SourceHealthWeights.balanced) return 'balanced';
    if (preset == SourceHealthWeights.playableFirst) return 'playable';
    return 'fresh';
  }

  static String _presetLabel(
    BuildContext context,
    SourceHealthWeights preset,
  ) {
    if (preset == SourceHealthWeights.balanced) {
      return context.loc.sourcesHealthPresetBalanced;
    }
    if (preset == SourceHealthWeights.playableFirst) {
      return context.loc.sourcesHealthPresetPlayable;
    }
    return context.loc.sourcesHealthPresetFresh;
  }
}

/// The twelve dimensions as two aligned columns of label and share.
class _ShareTable extends StatelessWidget {
  final SourceHealthWeights weights;

  const _ShareTable({required this.weights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = weights.total;
    int share(int value) => total == 0 ? 0 : (value * 100 / total).round();
    final entries = <(String, int)>[
      (context.loc.sourcesHealthAvailability, share(weights.availability)),
      (context.loc.sourcesHealthConfiguration, share(weights.configuration)),
      (context.loc.sourcesHealthScan, share(weights.scan)),
      (context.loc.sourcesHealthFreshness, share(weights.freshness)),
      (context.loc.sourcesHealthOutput, share(weights.output)),
      (context.loc.sourcesHealthSpeed, share(weights.speed)),
      (context.loc.sourcesHealthReliability, share(weights.reliability)),
      (context.loc.sourcesHealthStability, share(weights.stability)),
      (context.loc.sourcesHealthPlayable, share(weights.playable)),
      (context.loc.sourcesHealthArtwork, share(weights.artwork)),
      (context.loc.sourcesHealthMetadata, share(weights.metadata)),
      (context.loc.sourcesHealthActivity, share(weights.activity)),
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
            Expanded(child: _ShareColumn(entries: entries.sublist(0, 6))),
            VerticalDivider(
              width: CompactTokens.space20,
              thickness: 1,
              color: theme.colorScheme.outlineVariant,
            ),
            Expanded(child: _ShareColumn(entries: entries.sublist(6))),
          ],
        ),
      ),
    );
  }
}

class _ShareColumn extends StatelessWidget {
  final List<(String, int)> entries;

  const _ShareColumn({required this.entries});

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
                  '${entry.$2}%',
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
