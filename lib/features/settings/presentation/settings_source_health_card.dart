import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/source_health_weights.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_card_shell.dart';

/// Settings card for the weights of the source health dimensions.
///
/// The reader sees the normalized share of each dimension, not the raw
/// weight: a weight of 15 only means something next to the other eleven.
/// Three presets cover the common philosophies; the custom sheet has the
/// twelve steppers for the reader who wants them.
class SettingsSourceHealthCard extends ConsumerWidget {
  /// Whether the card stands inside the settings dashboard, where the
  /// section already names it. The nested header is dropped then.
  final bool embedded;

  const SettingsSourceHealthCard({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weights = ref.watch(
      settingsControllerProvider.select((state) => state.sourceHealthWeights),
    );
    final theme = Theme.of(context);

    final body = Column(
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
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        const SizedBox(height: CompactTokens.space8),
        _ShareTable(weights: weights),
        const SizedBox(height: CompactTokens.space6),
        Text(
          context.loc.sourcesHealthWeightsTotal(weights.total),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CompactTypography.mono(
            theme.colorScheme.onSurfaceVariant,
            size: CompactTypeScale.mark,
          ),
        ),
      ],
    );
    if (embedded) return body;
    return SettingsCard(
      index: '05',
      eyebrow: context.loc.sourcesTitle,
      title: context.loc.sourcesHealthWeightsTitle,
      description: context.loc.settingsSourceHealthDescription,
      child: body,
    );
  }

  static Future<void> _apply(WidgetRef ref, SourceHealthWeights weights) async {
    await ref
        .read(settingsControllerProvider.notifier)
        .setSourceHealthWeights(weights);
  }

  static String _presetId(SourceHealthWeights preset) {
    if (preset == SourceHealthWeights.balanced) return 'balanced';
    if (preset == SourceHealthWeights.playableFirst) return 'playable';
    return 'fresh';
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

/// The twelve dimensions in a compact grid: three columns on a wide card,
/// two on a narrow one. Each cell is a label and its normalized share.
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
        horizontal: CompactTokens.space8,
        vertical: CompactTokens.space4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(CompactTokens.radius10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 700
              ? 6
              : constraints.maxWidth >= 420
              ? 4
              : constraints.maxWidth >= 300
              ? 3
              : 2;
          final rows = (entries.length / columns).ceil();
          return Column(
            children: [
              for (var row = 0; row < rows; row++)
                Row(
                  children: [
                    for (var column = 0; column < columns; column++)
                      Expanded(
                        child: _ShareCell(
                          entry: row * columns + column < entries.length
                              ? entries[row * columns + column]
                              : null,
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ShareCell extends StatelessWidget {
  final (String, int)? entry;

  const _ShareCell({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CompactTokens.space4,
        vertical: 0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry!.$1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: CompactTokens.space4),
          Text(
            '${entry!.$2}%',
            style: CompactTypography.mono(
              theme.colorScheme.onSurface,
              size: CompactTypeScale.mark,
            ),
          ),
        ],
      ),
    );
  }
}
