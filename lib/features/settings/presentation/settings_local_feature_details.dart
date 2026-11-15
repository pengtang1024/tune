import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/config/app_capabilities.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_feature.dart';
import 'package:tune/features/local_components/application/local_components_controller.dart';
import 'package:tune/features/settings/presentation/settings_localization_local_block.dart'
    show formatComponentBytes;

/// The technical list under one feature card: every component it can own,
/// with its files and the one action that applies. Collapsed by default.
class SettingsLocalFeatureDetails extends ConsumerWidget {
  final LocalFeatureSpec feature;

  const SettingsLocalFeatureDetails({super.key, required this.feature});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = <String>{};
    final platform = AppCapabilities.current.platform;
    final components = [
      for (final spec in feature.allComponents)
        if (spec.supports(platform) && seen.add(spec.id)) spec,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final spec in components)
          _ComponentRow(
            spec: spec,
            state: ref.watch(localComponentStateProvider(spec.id)),
          ),
      ],
    );
  }
}

class _ComponentRow extends ConsumerWidget {
  final LocalComponentSpec spec;
  final LocalComponentState state;

  const _ComponentRow({required this.spec, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final downloading = state.phase == LocalComponentPhase.downloading;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CompactTokens.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  componentLabel(context, spec.label),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: CompactTokens.space4),
                Text(
                  _filesText(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: CompactTokens.space4),
                Text(
                  _statusText(context),
                  key: ValueKey('component-status-${spec.id}'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: state.phase == LocalComponentPhase.failed
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (state.phase == LocalComponentPhase.checking ||
              state.phase == LocalComponentPhase.verifying)
            Icon(
              Icons.hourglass_empty,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            )
          else if (downloading)
            TextButton(
              key: ValueKey('component-cancel-${spec.id}'),
              onPressed: () =>
                  ref.read(localComponentsControllerProvider.notifier).cancel(
                    spec.id,
                  ),
              child: Text(strings.cancel),
            )
          else if (state.ready && state.canDelete)
            TextButton(
              key: ValueKey('component-remove-${spec.id}'),
              onPressed: () => _confirmRemove(context, ref),
              child: Text(strings.settingsLocalizationLocalDelete),
            )
          else if (state.systemAvailable)
            const SizedBox.shrink()
          else
            TextButton(
              key: ValueKey('component-download-${spec.id}'),
              onPressed: () =>
                  ref.read(localComponentsControllerProvider.notifier).download(
                    spec.id,
                  ),
              child: Text(strings.settingsLocalizationLocalDownload),
            ),
        ],
      ),
    );
  }

  String _filesText() {
    return [
      for (final file in spec.files)
        '${file.fileName} · ${formatComponentBytes(file.bytes)} · '
            '${Uri.tryParse(file.url)?.host ?? ''}',
    ].join('\n');
  }

  String _statusText(BuildContext context) {
    final strings = context.loc;
    switch (state.phase) {
      case LocalComponentPhase.checking:
        return strings.settingsLocalizationLocalVerifying;
      case LocalComponentPhase.notInstalled:
        return state.systemAvailable
            ? strings.settingsLocalComponentsSystemHint
            : strings.settingsLocalizationLocalMissing;
      case LocalComponentPhase.downloading:
        final progress = state.progress;
        return progress == null
            ? strings.settingsLocalizationLocalDownloading
            : '${strings.settingsLocalizationLocalDownloading} '
                  '${(progress * 100).round()}% · '
                  '${formatComponentBytes(state.received)}'
                  ' / ${formatComponentBytes(state.total)}';
      case LocalComponentPhase.verifying:
        return strings.settingsLocalizationLocalVerifying;
      case LocalComponentPhase.ready:
        return state.systemAvailable
            ? '${strings.settingsLocalizationLocalReady} · '
                  '${strings.settingsLocalComponentsSystemHint}'
            : strings.settingsLocalizationLocalSize(
                formatComponentBytes(state.installedBytes),
              );
      case LocalComponentPhase.failed:
        return strings.settingsLocalizationLocalCorrupt;
    }
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final strings = context.loc;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.settingsLocalizationLocalDelete),
        content: Text(strings.settingsLocalizationLocalDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref
          .read(localComponentsControllerProvider.notifier)
          .remove(spec.id);
    }
  }
}

/// The reader-facing name of a component.
String componentLabel(BuildContext context, LocalComponentLabel label) {
  final strings = context.loc;
  return switch (label) {
    LocalComponentLabel.translationRuntime =>
      strings.settingsLocalComponentTranslationRuntime,
    LocalComponentLabel.translationModel =>
      strings.settingsLocalComponentTranslationModel,
    LocalComponentLabel.translationModelLow =>
      strings.settingsLocalComponentTranslationModelLow,
    LocalComponentLabel.translationModelQuality =>
      strings.settingsLocalComponentTranslationModelQuality,
    LocalComponentLabel.whisperRuntime =>
      strings.settingsLocalComponentWhisperRuntime,
    LocalComponentLabel.whisperModelTiny =>
      strings.settingsLocalComponentWhisperTiny,
    LocalComponentLabel.whisperModelBase =>
      strings.settingsLocalComponentWhisperBase,
    LocalComponentLabel.whisperModelSmall =>
      strings.settingsLocalComponentWhisperSmall,
    LocalComponentLabel.whisperOnnxModelSmall =>
      strings.settingsLocalComponentWhisperOnnxSmall,
    LocalComponentLabel.whisperModelLargeTurbo =>
      strings.settingsLocalComponentWhisperLargeTurbo,
    LocalComponentLabel.sherpaRuntime =>
      strings.settingsLocalComponentSherpaRuntime,
    LocalComponentLabel.sensevoiceModel =>
      strings.settingsLocalComponentSensevoiceModel,
    LocalComponentLabel.funasrNanoModel =>
      strings.settingsLocalComponentFunasrNanoModel,
    LocalComponentLabel.ffmpeg => strings.settingsLocalComponentFfmpeg,
  };
}
