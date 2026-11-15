import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/config/app_capabilities.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_feature.dart';
import 'package:tune/features/local_components/application/feature_recommendation.dart';
import 'package:tune/features/local_components/application/local_components_controller.dart';
import 'package:tune/features/local_components/application/local_feature_state.dart';
import 'package:tune/features/local_components/application/machine_profile_provider.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/domain/settings_state.dart';
import 'package:tune/features/settings/presentation/settings_local_feature_details.dart';
import 'package:tune/features/settings/presentation/settings_local_feature_labels.dart';
import 'package:tune/features/settings/presentation/settings_localization_local_block.dart'
    show formatComponentBytes;

/// One feature item: what it is for, the tier to install, and the technical
/// list behind a disclosure (docs/local-components.md §7.1).
class SettingsLocalFeatureCard extends ConsumerStatefulWidget {
  final LocalFeatureSpec feature;

  const SettingsLocalFeatureCard({super.key, required this.feature});

  @override
  ConsumerState<SettingsLocalFeatureCard> createState() =>
      _SettingsLocalFeatureCardState();
}

class _SettingsLocalFeatureCardState
    extends ConsumerState<SettingsLocalFeatureCard> {
  bool _expanded = false;

  /// The tier the reader just picked. It wins over the recommendation and the
  /// stored default, so choosing a lyrics tier before installing does not snap
  /// back on the next rebuild.
  String? _pickedTier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final feature = widget.feature;
    final platform = AppCapabilities.current.platform;
    final tiers = feature.tiersFor(platform);
    if (tiers.isEmpty) return const SizedBox.shrink();

    final states =
        ref.watch(localComponentsControllerProvider).valueOrNull ??
        const <String, LocalComponentState>{};
    final settings = ref.watch(settingsControllerProvider);
    final profile = ref.watch(machineProfileProvider).valueOrNull;
    final recommendation = profile == null
        ? null
        : recommendFeature(
            feature: feature,
            profile: profile,
            platform: platform,
            languageCode: Localizations.localeOf(context).languageCode,
            systemAvailable: {
              for (final entry in states.entries)
                if (entry.value.systemAvailable) entry.key,
            },
          );
    final tier = _selectedTier(tiers, states, settings, recommendation);
    final state = deriveFeatureState(feature, tier, states);
    final addons = [
      for (final addon in feature.addons)
        if (addon.supports(platform)) addon,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: CompactTokens.space12),
      padding: const EdgeInsets.all(CompactTokens.space12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(CompactTokens.radius12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      featureTitle(context, feature.label),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: CompactTokens.space4),
                    Text(
                      featureDescription(context, feature.label),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: CompactTokens.space8),
              _StatusPill(featureId: feature.id.name, state: state),
            ],
          ),
          if (state.phase == LocalFeaturePhase.downloading ||
              state.phase == LocalFeaturePhase.verifying) ...[
            const SizedBox(height: CompactTokens.space10),
            LinearProgressIndicator(value: state.progress),
          ],
          if (tiers.length > 1) ...[
            const SizedBox(height: CompactTokens.space12),
            Text(
              strings.settingsLocalFeatureTierTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            for (final option in tiers)
              _TierRow(
                key: ValueKey(
                  'feature-tier-${feature.id.name}-${option.id}',
                ),
                featureId: feature.id.name,
                tier: option,
                selected: option.id == tier.id,
                recommended: recommendation?.tier.id == option.id,
                certain: recommendation?.certain ?? false,
                onTap: () {
                  _rememberTier(option);
                  setState(() {});
                },
              ),
          ],
          if (addons.isNotEmpty) ...[
            const SizedBox(height: CompactTokens.space12),
            Text(
              strings.settingsLocalFeatureAddonsTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            for (final addon in addons)
              _AddonRow(
                key: ValueKey('feature-addon-${addon.label.name}'),
                addon: addon,
                states: states,
              ),
          ],
          const SizedBox(height: CompactTokens.space8),
          Row(
            children: [
              _primaryAction(tier, state),
              if (profile != null &&
                  profile.freeDiskBytes != null &&
                  profile.freeDiskBytes! <
                      tier.downloadBytes + tier.diskSlackBytes) ...[
                const SizedBox(width: CompactTokens.space8),
                Flexible(
                  child: Text(
                    strings.settingsLocalFeatureNotEnough,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_showsBundledOffer(feature, state)) ...[
            const SizedBox(height: CompactTokens.space4),
            Text(
              strings.settingsLocalFeatureSystemInUse,
              key: ValueKey('feature-system-note-${feature.id.name}'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            TextButton(
              key: ValueKey('feature-bundled-${feature.id.name}'),
              onPressed: () => _installBundled(tier),
              child: Text(
                strings.settingsLocalFeatureDownloadBundled(
                  formatComponentBytes(tier.downloadBytes),
                ),
              ),
            ),
          ],
          TextButton.icon(
            key: ValueKey('feature-details-${feature.id.name}'),
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              size: 18,
            ),
            label: Text(
              _expanded
                  ? strings.settingsLocalFeatureHideDetails
                  : strings.settingsLocalFeatureDetails,
            ),
          ),
          if (_expanded) SettingsLocalFeatureDetails(feature: feature),
        ],
      ),
    );
  }

  LocalFeatureTier _selectedTier(
    List<LocalFeatureTier> tiers,
    Map<String, LocalComponentState> states,
    SettingsState settings,
    FeatureRecommendation? recommendation,
  ) {
    final feature = widget.feature;
    final persisted = switch (feature.id) {
      LocalFeatureId.translation => settings.localization.localTier,
      LocalFeatureId.lyrics => settings.smartLyrics.localModel,
      LocalFeatureId.transcode => '',
    };
    final installed = feature.allComponents.any(
      (spec) => states[spec.id]?.usable ?? false,
    );
    final valid = tiers.any((tier) => tier.id == persisted);

    final picked = _pickedTier;
    if (picked != null && tiers.any((tier) => tier.id == picked)) {
      return tiers.firstWhere((tier) => tier.id == picked);
    }

    if (feature.id == LocalFeatureId.translation) {
      // A tier the reader picked by hand wins, even before it is installed.
      if (valid && persisted.isNotEmpty) {
        return tiers.firstWhere((tier) => tier.id == persisted);
      }
    } else if (installed && valid) {
      return tiers.firstWhere((tier) => tier.id == persisted);
    }

    final recommended = recommendation?.tier.id;
    if (recommended != null &&
        tiers.any((tier) => tier.id == recommended)) {
      return tiers.firstWhere((tier) => tier.id == recommended);
    }
    if (valid) return tiers.firstWhere((tier) => tier.id == persisted);
    return tiers.first;
  }

  void _rememberTier(LocalFeatureTier tier) {
    _pickedTier = tier.id;
    final settings = ref.read(settingsControllerProvider);
    switch (widget.feature.id) {
      case LocalFeatureId.translation:
        unawaited(
          ref
              .read(settingsControllerProvider.notifier)
              .setLocalization(
                settings.localization.copyWith(localTier: tier.id),
              ),
        );
      case LocalFeatureId.lyrics:
        // The ONNX tier has no whisper model name to persist.
        if (tier.id == 'android') return;
        unawaited(
          ref
              .read(settingsControllerProvider.notifier)
              .setSmartLyrics(
                settings.smartLyrics.copyWith(localModel: tier.id),
              ),
        );
      case LocalFeatureId.transcode:
        break;
    }
  }

  Widget _primaryAction(LocalFeatureTier tier, LocalFeatureState state) {
    final strings = context.loc;
    final controller = ref.read(localComponentsControllerProvider.notifier);
    final key = ValueKey('feature-action-${widget.feature.id.name}');

    switch (state.phase) {
      case LocalFeaturePhase.checking:
        return const SizedBox.shrink();
      case LocalFeaturePhase.downloading:
      case LocalFeaturePhase.verifying:
        return TextButton(
          key: key,
          onPressed: () => controller.cancelFeature(widget.feature, tier),
          child: Text(strings.settingsLocalFeatureCancel),
        );
      case LocalFeaturePhase.ready:
        if (!state.canDelete) return const SizedBox.shrink();
        return TextButton(
          key: key,
          onPressed: () => _confirmRemove(state),
          child: Text(strings.settingsLocalFeatureDelete),
        );
      case LocalFeaturePhase.partial:
        return FilledButton.tonal(
          key: key,
          onPressed: () => _install(tier),
          child: Text(
            strings.settingsLocalFeatureContinue(
              formatComponentBytes(state.missingBytes),
            ),
          ),
        );
      case LocalFeaturePhase.failed:
        return FilledButton.tonal(
          key: key,
          onPressed: () => _install(tier),
          child: Text(strings.settingsLocalFeatureRetry),
        );
      case LocalFeaturePhase.notInstalled:
        return FilledButton(
          key: key,
          onPressed: () => _install(tier),
          child: Text(strings.settingsLocalFeatureInstall),
        );
    }
  }

  /// Transcoding keeps working on the system binary; the bundled copy is only
  /// an offer, so the card says where the binary comes from and shows what a
  /// self-contained install would cost.
  bool _showsBundledOffer(LocalFeatureSpec feature, LocalFeatureState state) =>
      feature.id == LocalFeatureId.transcode &&
      state.phase == LocalFeaturePhase.ready &&
      state.systemOnly;

  Future<void> _install(LocalFeatureTier tier) async {
    _rememberTier(tier);
    await ref
        .read(localComponentsControllerProvider.notifier)
        .installFeature(widget.feature, tier);
  }

  /// Installs the bundled copy even though the system one already covers the
  /// feature. A normal feature install skips anything usable, so this goes
  /// through the same per-component download and verification instead.
  Future<void> _installBundled(LocalFeatureTier tier) async {
    final controller = ref.read(localComponentsControllerProvider.notifier);
    final states =
        ref.read(localComponentsControllerProvider).valueOrNull ??
        const <String, LocalComponentState>{};
    for (final spec in tier.components) {
      if (states[spec.id]?.phase == LocalComponentPhase.ready) continue;
      await controller.download(spec.id);
    }
  }

  Future<void> _confirmRemove(LocalFeatureState state) async {
    final strings = context.loc;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.settingsLocalFeatureDeleteTitle),
        content: Text(
          strings.settingsLocalFeatureDeleteBody(
            featureTitle(context, widget.feature.label),
            formatComponentBytes(state.installedBytes),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.settingsLocalFeatureDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref
          .read(localComponentsControllerProvider.notifier)
          .removeFeature(widget.feature);
    }
  }
}

class _StatusPill extends StatelessWidget {
  final String featureId;
  final LocalFeatureState state;

  const _StatusPill({required this.featureId, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = state.phase == LocalFeaturePhase.failed;
    final background = failed
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = failed
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(CompactTokens.radius6),
      ),
      child: Text(
        statusText(context, state),
        key: ValueKey('feature-status-$featureId'),
        style: theme.textTheme.labelSmall?.copyWith(color: foreground),
      ),
    );
  }
}

/// The one line that says where the feature stands.
String statusText(BuildContext context, LocalFeatureState state) {
  final strings = context.loc;
  return switch (state.phase) {
    LocalFeaturePhase.checking => strings.settingsLocalFeatureChecking,
    LocalFeaturePhase.notInstalled => strings.settingsLocalFeatureNeedDownload(
      formatComponentBytes(state.missingBytes),
    ),
    LocalFeaturePhase.downloading => strings.settingsLocalFeatureDownloading(
      ((state.progress ?? 0) * 100).round(),
    ),
    LocalFeaturePhase.verifying => strings.settingsLocalFeatureVerifying,
    LocalFeaturePhase.ready => state.systemOnly
        ? strings.settingsLocalFeatureSystemReady
        : strings.settingsLocalFeatureReady(
            formatComponentBytes(state.installedBytes),
          ),
    LocalFeaturePhase.partial => strings.settingsLocalFeaturePartial(
      state.completed,
      state.required,
    ),
    LocalFeaturePhase.failed => strings.settingsLocalFeatureFailed(
      state.message ?? '',
    ),
  };
}

class _TierRow extends StatelessWidget {
  final String featureId;
  final LocalFeatureTier tier;
  final bool selected;
  final bool recommended;
  final bool certain;
  final VoidCallback onTap;

  const _TierRow({
    super.key,
    required this.featureId,
    required this.tier,
    required this.selected,
    required this.recommended,
    required this.certain,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CompactTokens.radius8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CompactTokens.space6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: CompactTokens.space8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: CompactTokens.space6,
                    runSpacing: CompactTokens.space4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        tierTitle(context, tier.label),
                        style: theme.textTheme.labelMedium,
                      ),
                      if (recommended)
                        Text(
                          certain
                              ? strings.settingsLocalFeatureRecommended
                              : strings.settingsLocalFeatureDefaultChoice,
                          key: ValueKey('feature-recommended-$featureId'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: CompactTokens.space4),
                  Text(
                    tierDescription(context, tier.label),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: CompactTokens.space8),
            Text(
              formatComponentBytes(tier.downloadBytes),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddonRow extends ConsumerWidget {
  final LocalFeatureAddon addon;
  final Map<String, LocalComponentState> states;

  const _AddonRow({super.key, required this.addon, required this.states});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final controller = ref.read(localComponentsControllerProvider.notifier);
    final missing = [
      for (final spec in addon.components)
        if (!(states[spec.id]?.usable ?? false)) spec,
    ];
    final downloading = addon.components.any(
      (spec) => states[spec.id]?.phase == LocalComponentPhase.downloading,
    );
    final deletable = addon.components.any(
      (spec) => states[spec.id]?.canDelete ?? false,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CompactTokens.space6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addonTitle(context, addon.label),
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: CompactTokens.space4),
                Text(
                  addonDescription(context, addon.label),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: CompactTokens.space8),
          if (downloading)
            TextButton(
              onPressed: () {
                for (final spec in addon.components) {
                  controller.cancel(spec.id);
                }
              },
              child: Text(strings.settingsLocalFeatureCancel),
            )
          else if (missing.isEmpty)
            deletable
                ? TextButton(
                    onPressed: () => controller.removeComponents(addon.components),
                    child: Text(strings.settingsLocalFeatureDelete),
                  )
                : Text(
                    strings.settingsLocalFeatureAddonInstalled,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
          else
            TextButton(
              key: ValueKey('addon-install-${addon.label.name}'),
              onPressed: () async {
                await controller.installComponents(addon.components);
              },
              child: Text(
                '${strings.settingsLocalFeatureInstall} · '
                '${formatComponentBytes(
                  missing.fold(0, (sum, spec) => sum + spec.totalBytes),
                )}',
              ),
            ),
        ],
      ),
    );
  }
}
