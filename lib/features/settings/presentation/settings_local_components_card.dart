import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/config/app_capabilities.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/components/local_feature.dart';
import 'package:tune/features/settings/presentation/settings_local_feature_card.dart';

/// The one place every downloadable capability is installed, checked and
/// removed (docs/local-components.md §7).
///
/// A platform only sees the features its binaries can actually run; when it
/// can run none of them the whole block stays out of the page.
class SettingsLocalComponentsCard extends ConsumerWidget {
  const SettingsLocalComponentsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final platform = AppCapabilities.current.platform;
    final features = [
      for (final feature in LocalFeatureRegistry.all)
        if (feature.supports(AppCapabilities.current) &&
            feature.tiersFor(platform).isNotEmpty)
          feature,
    ];
    if (features.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final feature in features)
          SettingsLocalFeatureCard(
            key: ValueKey('feature-card-${feature.id.name}'),
            feature: feature,
          ),
        Text(
          strings.settingsLocalComponentsHint,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
