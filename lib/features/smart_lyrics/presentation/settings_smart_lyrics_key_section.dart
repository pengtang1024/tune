import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_config.dart';
import 'package:tune/features/smart_lyrics/presentation/settings_smart_lyrics_local_section.dart';
import 'package:tune/features/smart_lyrics/presentation/smart_lyrics_bound_field.dart';

/// The key hole and the endpoint preset of the smart lyrics pipeline
/// (docs/smart-lyrics.md §7.1).
///
/// The reader's moves: paste a key, pick a preset, and — folded away — the
/// endpoint and the model names. Every keystroke reaches the settings
/// controller at once, because the generate button reads the same state.
class SmartLyricsKeySection extends ConsumerWidget {
  const SmartLyricsKeySection({super.key});

  /// The name a preset carries in the menu; the brands keep their own.
  static const Map<String, String> _presetNames = {
    SmartLyricsPreset.openaiId: 'OpenAI',
    SmartLyricsPreset.groqId: 'Groq',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(settingsControllerProvider).smartLyrics;
    final strings = context.loc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('smart-lyrics-api-key'),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: strings.settingsSmartLyricsApiKey,
                  hintText: strings.settingsSmartLyricsApiKeyHint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (key) => _update(ref, config.copyWith(apiKey: key)),
              ),
            ),
            const SizedBox(width: CompactTokens.space12),
            Expanded(
              child: DropdownButtonFormField<String>(
                key: const ValueKey('smart-lyrics-preset'),
                initialValue: config.presetId,
                isDense: true,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: strings.settingsSmartLyricsPreset,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final preset in SmartLyricsPreset.all)
                    DropdownMenuItem(
                      value: preset.id,
                      child: Text(
                        _presetNames[preset.id] ??
                            strings.settingsSmartLyricsPresetCustom,
                      ),
                    ),
                ],
                onChanged: (selected) {
                  if (selected != null) _applyPreset(ref, selected);
                },
              ),
            ),
          ],
        ),
        _AdvancedFold(config: config),
        const SizedBox(height: CompactTokens.space12),
        const SmartLyricsLocalSection(),
      ],
    );
  }

  /// A preset brings its endpoint and its models with it; the reader's own
  /// keeps what is typed, so a tweak never erases the fields.
  void _applyPreset(WidgetRef ref, String id) {
    final config = ref.read(settingsControllerProvider).smartLyrics;
    final preset = SmartLyricsPreset.byId(id);
    _update(
      ref,
      preset.id == SmartLyricsPreset.customId
          ? config.copyWith(presetId: id)
          : config.copyWith(
              presetId: id,
              baseUrl: preset.baseUrl,
              asrModels: preset.asrModels,
              chatModel: preset.chatModel,
            ),
    );
  }

  void _update(WidgetRef ref, SmartLyricsConfig config) {
    ref.read(settingsControllerProvider.notifier).setSmartLyrics(config);
  }
}

/// The endpoint and the model names, folded until the reader asks for them.
class _AdvancedFold extends ConsumerStatefulWidget {
  final SmartLyricsConfig config;

  const _AdvancedFold({required this.config});

  @override
  ConsumerState<_AdvancedFold> createState() => _AdvancedFoldState();
}

class _AdvancedFoldState extends ConsumerState<_AdvancedFold> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final strings = context.loc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          key: const ValueKey('smart-lyrics-advanced'),
          onPressed: () => setState(() => _open = !_open),
          child: Text(strings.settingsSmartLyricsAdvanced),
        ),
        if (_open) ...[
          SmartLyricsBoundField(
            fieldKey: 'smart-lyrics-base-url',
            label: strings.settingsSmartLyricsBaseUrl,
            text: widget.config.baseUrl,
            onChanged: (value) =>
                _write(widget.config.copyWith(baseUrl: value)),
          ),
          SmartLyricsBoundField(
            fieldKey: 'smart-lyrics-asr-models',
            label: strings.settingsSmartLyricsAsrModels,
            text: widget.config.asrModels.join(', '),
            onChanged: (value) => _write(
              widget.config.copyWith(asrModels: _modelList(value)),
            ),
          ),
          SmartLyricsBoundField(
            fieldKey: 'smart-lyrics-chat-model',
            label: strings.settingsSmartLyricsChatModel,
            text: widget.config.chatModel,
            onChanged: (value) =>
                _write(widget.config.copyWith(chatModel: value)),
          ),
        ],
      ],
    );
  }

  void _write(SmartLyricsConfig config) {
    ref.read(settingsControllerProvider.notifier).setSmartLyrics(config);
  }

  /// The model names as the comma line the reader typed holds them.
  static List<String> _modelList(String text) => text
      .split(',')
      .map((model) => model.trim())
      .where((model) => model.isNotEmpty)
      .toList();
}
