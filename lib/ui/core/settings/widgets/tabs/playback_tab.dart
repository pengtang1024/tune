import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/core/settings/providers/playback_settings_provider.dart';

class PlaybackTab extends ConsumerStatefulWidget {
  const PlaybackTab({super.key});

  @override
  ConsumerState<PlaybackTab> createState() => _PlaybackTabState();
}

class _PlaybackTabState extends ConsumerState<PlaybackTab> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playbackSettingsProvider);
    final notifier = ref.read(playbackSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.settings),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 播放模式设置
            Text(
              context.loc.playback_mode,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: state.playMode,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  notifier.updatePlaybackMode(newValue);
                }
              },
              items: <String>[
                'sequence',
                'loop', 
                'single',
                'random'
              ].map<DropdownMenuItem<String>>((String value) {
                String text;
                switch (value) {
                  case 'sequence':
                    text = context.loc.repeat_all;
                    break;
                  case 'loop':
                    text = context.loc.repeat_all; // 可以根据需要调整
                    break;
                  case 'single':
                    text = context.loc.repeat_one;
                    break;
                  case 'random':
                    text = context.loc.shuffle;
                    break;
                  default:
                    text = value;
                }
                
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(text),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // 音效设置
            Text(
              context.loc.audio_effects,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.loc.enable_equalizer),
                Switch(
                  value: state.isEqualizerEnabled,
                  onChanged: notifier.toggleEqualizer,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.loc.bass_boost),
                Switch(
                  value: state.isBassBoostEnabled,
                  onChanged: notifier.toggleBassBoost,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.loc.spatial_audio),
                Switch(
                  value: state.isSpatialAudioEnabled,
                  onChanged: notifier.toggleSpatialAudio,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}