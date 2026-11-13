import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_component_registry.dart';
import 'package:tune/features/local_components/application/local_components_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_localization_local_block.dart'
    show formatComponentBytes;

/// The free vote of the pool (docs/smart-lyrics.md §6.2, M4): the reader
/// picks a whisper model, the shared installer brings it home, and from then
/// on one machine vote costs nothing and sends nothing.
class SmartLyricsLocalSection extends ConsumerWidget {
  const SmartLyricsLocalSection({super.key});

  /// The models the app offers; the names are the ones whisper.cpp uses.
  /// large-v3-turbo is an optional quality pack and never the default.
  static const List<String> models = [
    'tiny',
    'base',
    'small',
    'large-v3-turbo',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final config = ref.watch(settingsControllerProvider).smartLyrics;
    final strings = context.loc;
    final model = config.localModel;
    final state = model.isEmpty
        ? null
        : ref.watch(
            localComponentStateProvider(
              LocalComponentRegistry.whisperModel(model).id,
            ),
          );
    final downloading = state?.phase == LocalComponentPhase.downloading;
    final canDelete = state?.canDelete ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: const ValueKey('smart-lyrics-local-model'),
                initialValue: model.isEmpty ? '' : model,
                isDense: true,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: strings.settingsSmartLyricsLocal,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(strings.settingsSmartLyricsLocalOff),
                  ),
                  for (final name in models)
                    DropdownMenuItem(value: name, child: Text(name)),
                ],
                onChanged: (selected) {
                  if (selected == null) return;
                  ref
                      .read(settingsControllerProvider.notifier)
                      .setSmartLyrics(config.copyWith(localModel: selected));
                },
              ),
            ),
            const SizedBox(width: CompactTokens.space12),
            TextButton(
              key: const ValueKey('smart-lyrics-local-download'),
              onPressed: state == null
                  ? null
                  : downloading
                  ? () => _cancel(ref, model)
                  : state.busy
                  ? null
                  : canDelete
                  ? () => _remove(ref, model)
                  : () => _download(ref, model),
              child: Text(
                downloading
                    ? strings.settingsSmartLyricsLocalBusy
                    : state != null && state.ready && canDelete
                    ? strings.settingsLocalizationLocalDelete
                    : strings.settingsSmartLyricsLocalDownload,
              ),
            ),
          ],
        ),
        if (state != null) ...[
          const SizedBox(height: CompactTokens.space6),
          Text(
            _statusText(context, state),
            key: const ValueKey('smart-lyrics-local-status'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: state.phase == LocalComponentPhase.failed
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  String _statusText(BuildContext context, LocalComponentState state) {
    final strings = context.loc;
    switch (state.phase) {
      case LocalComponentPhase.checking:
        return '';
      case LocalComponentPhase.downloading:
      case LocalComponentPhase.verifying:
        final progress = state.progress;
        return progress == null
            ? strings.settingsSmartLyricsLocalBusy
            : '${(progress * 100).round()}% · '
                  '${formatComponentBytes(state.received)}'
                  ' / ${formatComponentBytes(state.total)}';
      case LocalComponentPhase.ready:
        return strings.settingsLocalizationLocalSize(
          formatComponentBytes(state.installedBytes),
        );
      case LocalComponentPhase.failed:
        return strings.settingsSmartLyricsLocalFailed;
      case LocalComponentPhase.notInstalled:
        return state.systemAvailable
            ? strings.settingsLocalComponentsSystemHint
            : strings.settingsLocalizationLocalMissing;
    }
  }

  void _download(WidgetRef ref, String model) {
    ref
        .read(localComponentsControllerProvider.notifier)
        .download(LocalComponentRegistry.whisperModel(model).id);
  }

  void _cancel(WidgetRef ref, String model) {
    ref
        .read(localComponentsControllerProvider.notifier)
        .cancel(LocalComponentRegistry.whisperModel(model).id);
  }

  Future<void> _remove(WidgetRef ref, String model) async {
    await ref
        .read(localComponentsControllerProvider.notifier)
        .remove(LocalComponentRegistry.whisperModel(model).id);
  }
}
