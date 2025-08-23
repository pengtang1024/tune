import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/core/settings/providers/playback_settings_provider.dart';

/// 播放设置标签页
class PlaybackTab extends ConsumerWidget {
  const PlaybackTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playbackSettingsProvider);
    final notifier = ref.read(playbackSettingsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.playback_settings,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String?>(
            value: state.playMode,
            decoration: InputDecoration(
              labelText: context.loc.play_mode,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: 'sequence',
                child: Text(context.loc.sequence_playback),
              ),
              DropdownMenuItem(
                value: 'repeat_one',
                child: Text(context.loc.repeat_one),
              ),
              DropdownMenuItem(
                value: 'shuffle',
                child: Text(context.loc.shuffle_playback),
              ),
            ],
            onChanged: (String? value) {
              if (value != null) {
                notifier.updatePlaybackMode(value);
              }
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String?>(
            value: state.audioQuality,
            decoration: InputDecoration(
              labelText: context.loc.audio_quality,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: 'low',
                child: Text(context.loc.low_quality),
              ),
              DropdownMenuItem(
                value: 'medium',
                child: Text(context.loc.medium_quality),
              ),
              DropdownMenuItem(
                value: 'high',
                child: Text(context.loc.high_quality),
              ),
            ],
            onChanged: (String? value) {
              if (value != null) {
                notifier.updateAudioQuality(value);
              }
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.loc.pause_when_headset_disconnected),
              Switch(
                value: state.pauseWhenHeadsetDisconnected,
                onChanged: notifier.updatePauseWhenHeadsetDisconnected,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            context.loc.audio_effects,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.loc.enable_equalizer),
              Switch(
                value: state.isEqualizerEnabled,
                onChanged: (bool value) {
                  notifier.toggleEqualizer(value);
                },
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
                onChanged: (bool value) {
                  notifier.toggleBassBoost(value);
                },
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
                onChanged: (bool value) {
                  notifier.toggleSpatialAudio(value);
                },
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                notifier.saveSettings();
                // 显示保存成功的提示
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.loc.settings_saved)),
                );
              },
              child: Text(context.loc.save),
            ),
          ),
        ],
      ),
    );
  }
}