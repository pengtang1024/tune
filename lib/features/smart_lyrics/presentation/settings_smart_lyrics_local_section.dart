import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/smart_lyrics/whisper_assets.dart';
import 'package:tune/data/services/smart_lyrics/whisper_model_store.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/utils/logger.dart';

/// The store the local models are downloaded through, on this machine.
final whisperModelStoreProvider = FutureProvider<WhisperModelStore>((
  ref,
) async {
  final assets = await WhisperAssets.appDefault();
  return WhisperModelStore(root: Directory(assets.modelsFolder));
});

/// The free vote of the pool (docs/smart-lyrics.md §6.2, M4): the reader
/// picks a whisper model, the app brings it home, and from then on one
/// machine vote costs nothing and sends nothing.
class SmartLyricsLocalSection extends ConsumerStatefulWidget {
  const SmartLyricsLocalSection({super.key});

  @override
  ConsumerState<SmartLyricsLocalSection> createState() =>
      _SmartLyricsLocalSectionState();
}

class _SmartLyricsLocalSectionState
    extends ConsumerState<SmartLyricsLocalSection> {
  /// The models the app offers; the names are the ones whisper.cpp uses.
  static const List<String> _models = ['tiny', 'base', 'small'];

  bool _downloading = false;

  /// The words the last download ended with; `null` while nothing was tried.
  String? _result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = ref.watch(settingsControllerProvider).smartLyrics;
    final strings = context.loc;
    final model = config.localModel;
    final result = _result;

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
                  for (final name in _models)
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
              onPressed: model.isEmpty || _downloading
                  ? null
                  : () => _download(model),
              child: Text(
                _downloading
                    ? strings.settingsSmartLyricsLocalBusy
                    : strings.settingsSmartLyricsLocalDownload,
              ),
            ),
          ],
        ),
        // The words the last download ended with: a success the reader
        // can act on, or a failure they can press through.
        if (result != null) ...[
          const SizedBox(height: CompactTokens.space6),
          Text(
            result,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _download(String model) async {
    final strings = context.loc;
    setState(() {
      _downloading = true;
      _result = null;
    });
    try {
      final store = await ref.read(whisperModelStoreProvider.future);
      final checksum = await store.checksumOf(model);
      if (checksum == null) throw WhisperModelException('no checksum');
      await store.download(model, checksum: checksum);
      setState(() => _result = strings.settingsSmartLyricsLocalReady);
    } catch (error, stackTrace) {
      Log.error('本地模型下载失败: $error', stackTrace);
      setState(() => _result = strings.settingsSmartLyricsLocalFailed);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }
}
