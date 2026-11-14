import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/config/app_capabilities.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_component_registry.dart';
import 'package:tune/features/local_components/application/local_components_controller.dart';
import 'package:tune/features/settings/presentation/settings_localization_local_block.dart'
    show formatComponentBytes;

/// The one place every downloadable capability is installed, checked and
/// removed (docs/local-components.md §7).
class SettingsLocalComponentsCard extends ConsumerWidget {
  const SettingsLocalComponentsCard({super.key});

  static const Map<String, List<LocalComponentSpec>> _groups = {
    'translation': [
      LocalComponentRegistry.translationRuntime,
      ...LocalComponentRegistry.translationModels,
    ],
    'lyrics': [
      LocalComponentRegistry.whisperRuntime,
      ...LocalComponentRegistry.whisperModels,
      LocalComponentRegistry.whisperOnnxModelSmall,
      LocalComponentRegistry.sherpaRuntime,
      LocalComponentRegistry.sensevoiceModel,
      LocalComponentRegistry.funasrNanoModel,
    ],
    'transcode': [LocalComponentRegistry.ffmpeg],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The scan itself is quick; while it runs the rows say they are checking
    // instead of showing a bar that would keep animating if the platform
    // never answers.
    ref.watch(localComponentsControllerProvider);
    final theme = Theme.of(context);
    final strings = context.loc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in _groups.entries) ...[
          _GroupTitle(text: _groupTitle(context, group.key)),
          for (final spec in group.value)
            if (spec.supports(AppCapabilities.current.platform))
              _ComponentRow(
                spec: spec,
                state: ref.watch(localComponentStateProvider(spec.id)),
              ),
          const SizedBox(height: CompactTokens.space8),
        ],
        Text(
          strings.settingsLocalComponentsHint,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _groupTitle(BuildContext context, String group) {
    final strings = context.loc;
    return switch (group) {
      'translation' => strings.settingsLocalComponentsGroupTranslation,
      'lyrics' => strings.settingsLocalComponentsGroupLyrics,
      _ => strings.settingsLocalComponentsGroupTranscode,
    };
  }
}

class _GroupTitle extends StatelessWidget {
  final String text;

  const _GroupTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: CompactTokens.space8),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
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
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  componentLabel(context, spec.label),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
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
